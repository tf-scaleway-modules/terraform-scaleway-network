# Tasks

## 1. Tooling

- [x] 1.1 Pin node and `openspec` in `mise.toml`; add `spec-validate` and `spec-setup` tasks
- [x] 1.2 Add `scripts/openspec-setup.sh`, `.gitlab/specs.yml` and `OPENSPEC_VERSION` in `.gitlab/global.yml`
- [x] 1.3 Install `openspec-*` skills in `.claude/skills/` and `.opencode/skills/`

## 2. Configuration

- [x] 2.1 Fill `openspec/config.yaml` context, rules and operations for this module (git-cliff CHANGELOG, `tofu test`, no scan task)
- [x] 2.2 Fill `AGENTS.md` and add `CLAUDE.md`

## 3. Baseline specs

- [x] 3.1 Write delta specs for `module-contract`, `vpc`, `private-networks`, `public-gateways`, `access-control-list` from the code; every validation block has a rejected-input scenario
- [x] 3.2 `openspec validate --all --strict` passes (same command as the `validate:specs` CI job)
- [x] 3.3 Archive the change and replace the TBD purposes

## 4. Documentation and checks

- [x] 4.1 README "Contributing": OpenSpec paragraph, `mise run spec-setup`, `mise run spec-validate`
- [x] 4.2 Verify no `.tf` file changed
- [x] 4.3 `pre-commit run` on the changed files passes
