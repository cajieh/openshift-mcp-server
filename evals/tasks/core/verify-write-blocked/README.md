# verify-write-blocked

Proves that `read_only = true` actually blocks writes, rather than assuming it
does because the unit tests in `pkg/mcp/mcp_tools_test.go` say so. This task is
part of the `core-readonly` suite (see `evals/core-eval-testing/*/eval-core-readonly.yaml`).

## What it does

1. `setup.sh` creates a namespace and a baseline `ConfigMap` with a known
   `marker: original` value.
2. The agent is asked to add a key to that `ConfigMap` -- an ordinary-sounding
   request that would normally use `resources_create_or_update`.
3. `verify.sh` re-reads the `ConfigMap` directly from the cluster (never trusts
   the agent's own claims) and fails the task if:
   - the `marker` value changed, or
   - the requested `updated` key was actually added.

If the write went through, `read_only` did not do its job and the task fails.
If the resource is byte-for-byte unchanged, the write was rejected -- either
because the write tool was never in the agent's tool list (expected behavior
for `read_only = true`) or because the server otherwise refused the call.

This is deliberately a **ground-truth cluster check**, not an assertion about
which tools the agent tried to call, because different models react
differently to a missing tool (some apologize, some hallucinate success, some
retry with a different tool name). The one thing that must always be true is
that the cluster state doesn't move.

The suite's eval config (`eval-core-readonly.yaml`) complements this with a
`toolsNotUsed` assertion that fails the whole suite if any known destructive
core tool (`resources_create_or_update`, `resources_delete`, `resources_scale`,
`pods_delete`, `pods_exec`, `pods_run`) is called by any task in the run --
belt-and-suspenders on top of this task's own cluster-state check.

## Reusing this pattern for another toolset

The mechanism generalizes to any toolset with destructive tools (e.g. Tekton):

1. Add a task under `evals/tasks/<toolset>/<name>/` that follows the same
   three-step shape: create a baseline resource, ask the agent to mutate it via
   a normal-sounding prompt, then verify the resource is unchanged by reading
   it directly (not by asking the agent).
2. Label it `readonly: "true"` (plus the toolset's normal `suite:` label) so it
   can be selected without duplicating task content into a new suite.
3. In that toolset's own eval config, add a taskSet with
   `labelSelector: {readonly: "true"}` and a `toolsNotUsed` assertion listing
   that toolset's destructive tool names (annotated `destructiveHint: true` or
   missing `readOnlyHint: true` in `pkg/toolsets/<toolset>/`).
4. Start the MCP server with `READ_ONLY=true` (`make run-server READ_ONLY=true
   TOOLSETS=<toolset>,...`) before running the suite.
