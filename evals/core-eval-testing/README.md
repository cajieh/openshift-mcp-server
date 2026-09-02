# Core Eval Testing

Eval configurations for running **core** task suites (core, config, helm, core-readonly) across different LLM providers and agent types.

## Naming

"Core" refers to the foundational task suites: `core`, `config`, `helm`, and `core-readonly`. Each subdirectory contains eval configs for these suites using a specific provider/agent combination (not every agent has every suite yet — see below).

## Directory structure

Each subdirectory follows the pattern `<agent-type>-<provider>/`:

- `builtin-*` — uses the built-in `llm-agent` with the provider's API directly
- `acp-*` — uses the Agent Communication Protocol (ACP) with an external agent process

Each contains:
- `agent.yaml` — agent configuration (model, type)
- `eval-core.yaml` — eval config for the `core` task suite
- `eval-config.yaml` — eval config for the `config` task suite
- `eval-helm.yaml` — eval config for the `helm` task suite
- `eval-core-readonly.yaml` (`builtin-openai` only so far) — eval config for the
  `core-readonly` suite, which proves the MCP server behaves correctly when
  started with `read_only=true`: reasonable read-only tasks still succeed, and
  a write attempt is actively rejected (not just assumed). It reuses the
  read-only-compatible tasks from `core`/`config` via a `readonly: "true"`
  label instead of duplicating them — see `evals/tasks/core/verify-write-blocked/README.md`
  for the full pattern, including how to reuse it for another toolset (e.g. Tekton).
  Run it with:
  ```bash
  make run-server READ_ONLY=true TOOLSETS=core,config
  make run-evals SUITE=core-readonly
  ```

## Design decisions

- **Shared tasks**: All eval configs reference the same task definitions via `../../tasks/*/*/*.yaml` with `labelSelector` to filter by suite.
- **Shared MCP config**: All configs use `../../mcp-config.yaml` to connect to the same MCP server instance.
- **Per-suite eval files**: Separate eval files per suite (instead of one combined file) allow running suites independently and setting different assertions (e.g., `maxToolCalls`).
