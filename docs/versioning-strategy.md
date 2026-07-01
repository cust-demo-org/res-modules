# Versioning & Release Strategy

Status: **Design agreed — implementation not started.**
Scope: How the Terraform resource modules in this repo are versioned, released, and traced back to a release once vendored into a consuming project.

This document is the single source of truth for versioning. It is a living plan; update it as decisions change.

---

## Consumption model (why this design)

Consumers **vendor modules by copy-paste** — they copy the module folders they need into their own project's `modules/` directory (see [`cust-demo-org/ai-landing-zone`](https://github.com/cust-demo-org/ai-landing-zone)). There is **no registry, no git source, and no per-module pinning**. Once a folder is copied, it is completely divorced from this repo's git history.

Two consequences drive everything below:

- A **single repo-wide version** is the right granularity — there is no mechanism for consumers to pin individual modules, so per-module registry versions would add complexity with no benefit.
- Each vendored copy needs an embedded **provenance stamp**, because the copy has no other link back to the release it came from.

---

## Versioning scheme

- **Repo-wide [Semantic Versioning](https://semver.org/)**: `vMAJOR.MINOR.PATCH`, one tag per release off `main`.
- The version identifies a **snapshot of the whole repo**, not any individual module.

### Bump semantics (mono-repo)

Because one version spans all modules, "breaking" is evaluated across the whole repo:

| Bump | Triggered by (in **any** module) |
|---|---|
| **MAJOR** | Backward-incompatible change: removed/renamed input variable, removed/renamed output, a changed default that alters deployed resources, a breaking required-provider bump, or an **AVM source bump that changes the module interface or forces resource replacement**. |
| **MINOR** | Backward-compatible addition: new optional variable, new output, a **whole new module**, a non-breaking AVM bump that adds capability. |
| **PATCH** | Backward-compatible fix: bug fix with no interface change, internal refactor, docs, CI. |

### AVM-bump rule

AVM source bumps are the most common change and can be major, minor, or patch depending on what the upstream release did. **Every AVM bump is assessed for breaking-ness.** The testing pipeline's **Stage 2 "no `replace`/`destroy`" result is the objective signal**: if upgrading forces resource replacement, treat it as at least a behavioral break and flag it for a MAJOR bump.

---

## Per-module provenance stamp (`metadata.yaml`)

Every module folder contains a machine-managed `metadata.yaml`. It is the **only provenance link** a vendored copy retains.

```yaml
# Auto-generated provenance stamp — managed by the release pipeline. Do not hand-edit.
module: cosmos_db
res_modules_version: 1.4.0        # repo release this copy corresponds to (uniform across all modules)
module_last_changed: 1.3.0        # repo release in which THIS module last changed functionally
source_repo: https://github.com/cust-demo-org/res-modules
avm_source: Azure/avm-res-documentdb-databaseaccount/azurerm   # optional provenance
avm_version: 0.10.0                                            # optional; changes only on AVM bump
```

- `res_modules_version` — moves to the new version on **every** release, uniform across all modules. Answers "which release did I copy from?"
- `module_last_changed` — moves **only when this module's `.tf` changes**. Answers "has my module actually changed since I copied it?"
- `avm_source` / `avm_version` — optional provenance for a copy divorced from the repo; scaffolded by the creator skill, updated when the AVM source is bumped.
- **No date field** — versions give exact provenance; dates are recoverable from the CHANGELOG/tags.

### How `module_last_changed` is guaranteed (computed, never hand-set)

It is **computed deterministically in the release pipeline** from the git diff of the module folder — never maintained by hand or by a skill (either would drift the first time someone forgets).

1. `release-please` determines the next repo-wide version `X.Y.Z`.
2. For each module folder, check whether it changed **functionally** since the previous release tag:
   ```
   git diff --quiet <last-tag> HEAD -- <module>/ \
     ':!<module>/metadata.yaml' ':!<module>/README.md' \
     ':!<module>/_header.md' ':!<module>/_footer.md' ':!<module>/.terraform-docs.yml'
   ```
   Only `.tf` changes count; docs and the stamp file itself are excluded.
3. If the folder changed → set `module_last_changed: X.Y.Z`. Always set `res_modules_version: X.Y.Z`.
4. Commit the metadata edits into the **release PR** so they land atomically with the tag.

This is the **same folder-diff logic as the testing change-detection** ([testing-strategy.md](testing-strategy.md)). "What counts as a module change" is defined **once** and reused for both which tests run and which modules get `module_last_changed` bumped.

**Edge cases:**
- **First release (1.0.0):** no previous tag → `module_last_changed = 1.0.0` for all modules (baseline).
- **`metadata.yaml` is excluded from the functional diff** — otherwise stamping it would self-register as a change.
- **Docs-only changes** don't bump `module_last_changed`, consistent with the testing filter.
- **New module added mid-cycle:** the creator skill scaffolds `metadata.yaml` with placeholder versions (`0.0.0-unreleased`); the pipeline stamps both fields at the next release.

---

## Release mechanism

- **[Conventional Commits](https://www.conventionalcommits.org/) + [`release-please`](https://github.com/googleapis/release-please) (simple mode).**
- `release-please` maintains the single repo-wide version, accumulates changes into a **release PR**, and on merge tags the release and updates the CHANGELOG.
- On release, `release-please` (via its `extra-files` updaters) plus the folder-diff step stamps every module's `metadata.yaml`.
- **Commit scopes carry the module name** (`feat(cosmos_db): …`, `fix(public_ip): …`) to drive per-module CHANGELOG grouping. The scope is a cross-check; the **folder diff is authoritative** for `module_last_changed`.

### Skill responsibilities

The AI skills (creator/wirer/docs) support versioning but never write authoritative version numbers:
- **Creator** scaffolds `metadata.yaml` with placeholder versions and the `avm_source`/`avm_version` provenance.
- All skills **emit module-scoped conventional-commit messages**.

---

## CHANGELOG

- A single root **`CHANGELOG.md`**, **per-module-aware** — each release section attributes changes to the modules they touched (driven by commit scopes).
- This is **mandatory**, not optional: it is how a vendored user who stamped at `1.4.0` decides whether a newer release affects the specific modules they copied. They read that module's entries between their `res_modules_version` and the latest release.

---

## Support policy

- **Latest major only. No backports.** When `v2.0.0` ships, fixes are not backported to `v1.x`.
- Because consumers vendor by copy-paste and are never force-upgraded, a new major is a **communication signal**, not a forced break — copied code keeps working until the consumer chooses to re-copy.

---

## Pre-1.0 handling

- The repo stays **untagged** until modules are validated by the testing pipeline (Tier 0 + Stage 1) and we jointly agree to cut **1.0.0**.
- `1.0.0` is cut on **validated code** — the first tag that has passed the pipeline — not on the current untested state.
- No `0.x` interim tags unless a concrete need for an intermediate baseline arises.

---

## Interaction with testing (Stage 2)

Repo-wide semver keeps Stage 2 simple: it resolves the **single latest `vX.Y.Z` tag**, checks out that module's code as the "released" baseline, and diffs the PR against it — no per-module tag arithmetic. See [testing-strategy.md](testing-strategy.md).

---

## Open / deferred items

- `release-please` config specifics (simple mode + `extra-files` list vs. a post-release stamping script for the ~15 `metadata.yaml` files).
- Whether `avm_source`/`avm_version` are auto-extracted from module source at release time or maintained by the creator skill.
- Updating the three AI skills to scaffold `metadata.yaml` and emit scoped commits (separate implementation task).
- Timing of the first `1.0.0` tag (jointly decided after validation).
