# lookin — Pipeline Catalog

Run any pipeline with `bin/pf pipelines/<file>`. Doc = Code: each pipeline's own `.md` header is the source of truth — this catalog is descriptive lookup only. Naming conventions: see `claude-base/docs/rules/01_research_design/architecture_and_pipelines.md`.

## Ops

| File | trigger | tenant | Called by | Summary |
|---|---|---|---|---|
| OPS-deploy_lookin.md | manual | — | human | Deploy static LookIn assets and symlink into registered projects, with no build step (lookin must stay static); connection comes from env vars. |
