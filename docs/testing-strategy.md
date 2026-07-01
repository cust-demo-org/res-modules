# Testing & Validation Strategy

Status: **Design agreed — implementation not started.**
Scope: Automated example-based testing and PR-gating for the Terraform resource modules in this repo, packaged for reuse across sibling repos.

This document is the single source of truth for the testing design. It is a living plan; update it as decisions change.

---

## Goals

- One runnable `examples/` config per module that doubles as **documentation** and as the **test fixture**.
- Pre-merge PR gating in GitHub Actions, tiered by cost/speed.
- **Stage 1 — idempotency:** a change applies cleanly and is stable (no perpetual diff).
- **Stage 2 — regression:** upgrading from the latest release to new code does not force resource replacement/destroy (no data loss / downtime).
- Only test the **changed module(s) and their dependents**.
- Handle known provider noise (azapi, diagnostic settings) without masking real regressions.
- **Reusable across repos** — no repo-specific hardcodes; env specifics passed as inputs/secrets/vars.
- Scripts also runnable **locally** as a `pr-check` command before opening a PR.

---

## Examples & fixtures

- **One canonical `examples/` config per module.** Examples serve triple duty: docs, test fixture, and integration proof of key-based referencing.
- **Two dependency classes, handled differently:**
  - **External (pattern-module) dependencies** — resource group, VNet/subnet, Key Vault + key, managed identity, private DNS zone, Log Analytics workspace, storage account. Produced by external `ptn-*` repos, not by anything here → **azurerm stubs** in a shared, toggleable fixtures module (e.g. `create_key_vault`, `create_dns_zones`, `create_managed_identity`) so each example provisions only its minimal dependency set.
  - **Internal (sibling-module) dependencies** — modules in *this* repo consumed by other modules → **use the real sibling module** (integration coverage of the repo's core value; examples stay truthful as docs).
- **Contract-drift control:** fixture output-map shapes are copied from the pattern modules' `outputs.tf`, with the source version recorded. Revisit when pattern modules change their output contract.
- Fixtures and the module-under-test live in the **same root config / same apply**; input maps are assembled in `locals` and resolved by the module via key-based referencing.

### Internal dependents map

Used for change detection ("changed module + its dependents both run"):

| Changed module | Also test |
|---|---|
| `app_service_plan` | `web_site` |
| `application_insights` | `web_site` |
| `disk_encryption_set` | `virtual_machine` |
| `public_ip` | `application_gateway`, `api_management_service` |
| `web_application_firewall_policy` | `application_gateway` |
| `email_communication_services` | `communication_services` |

A change to **shared fixtures, scripts, or the workflow** triggers **all** modules.

---

## Change detection

- Git-diff path filtering on **`.tf` files only** (docs-only changes do not trigger deploys) → dynamic job matrix.
- Expand the matrix with the internal dependents map above.
- Shared fixtures/scripts/workflow changes → full matrix.

---

## Pipeline tiers

| Tier | Trigger | Steps |
|---|---|---|
| **Tier 0 — static** | Every PR, **always required** | `fmt`, `validate`, `tflint`, docs-drift check, `plan` |
| **Stage 1 — idempotency** | Explicit (label / `/test`) | `init` → `apply` → `apply` (`plan -detailed-exitcode` = no changes) → `destroy` |
| **Stage 2 — regression** | Explicit / nightly | deploy latest release → switch to new code → `plan` → **assert no `replace`/`destroy`** → plan surfaced as artifact/PR comment → **Environment-gated human approval** for in-place changes → `destroy` |

### Gatekeeper (avoids stuck PRs)

A single **always-required** gatekeeper job passes when **either**:
- no `.tf` files changed, **or**
- the explicitly-triggered integration run was executed and passed.

This lets the heavy tiers be blocking *when relevant* without leaving docs-only PRs stuck on a check that never runs.

---

## Noise handling

- **Codified expected-diff baselines per example = primary path.** Reviewed in the PR, diffable in git.
- **Manual override = narrow break-glass:** gated by a GitHub Environment + required reviewer, requires a **recorded reason**, and should prompt codifying the noise back into the baseline (a field overridden twice belongs in the baseline).
- **Hard guardrail:** override/approval may **never** greenlight a `replace`/`destroy`. The automated Stage 2 check fails outright on replacement; the human gate only judges *in-place* noise.

---

## Stage 2 assertion detail

- Pass condition is **"no `replace`/`destroy` actions,"** not "zero diff." In-place updates are expected and fine (new features, provider bumps).
- Mechanics via `terraform plan -detailed-exitcode` (0 = no change, 2 = change); the *assertion* inspects planned actions for replacement.
- The post-upgrade plan is surfaced as an artifact / PR comment so the human reviewer approves against real evidence.

---

## Tooling & reuse

- Orchestration logic lives in **versioned pwsh scripts** (e.g. `Invoke-Stage1.ps1`, `Invoke-Stage2.ps1`, `Get-ChangedModules.ps1`), not inline YAML. The workflow only calls them.
- Scripts accept a **`-Local`** switch (uses `az login` context instead of OIDC; dev-scoped state key) and are packaged as a local **`pr-check`** command so devs can run the same checks before opening a PR. CI and local invoke the *same* scripts — no drift.
- Packaged as a **reusable workflow (`workflow_call`) / composite action**; convention-driven discovery of `*/examples/`; all environment specifics (subscription, region, naming prefix, backend) passed as **inputs/secrets/vars** — no hardcodes.

---

## Azure & runtime

- Runs against a nominated subscription (initially personal); all details variabilised.
- **OIDC federated auth** preferred over long-lived secrets. Identity needs `Contributor` on the subscription + `Storage Blob Data Contributor` on the state account.
- **Remote state** on a preexisting storage account; **state key per run**: `<module>/<git-sha>-<run-id>.tfstate`; backend supplied via `-backend-config` (nothing hardcoded).
- **Unique run-id naming** for all globally-unique resources (fixtures and modules-under-test).
- **Soft-delete purge** handling for Key Vault / APIM / Cosmos to avoid rerun name collisions.
- **Nightly janitor** deletes leaked resources by `test-run=true` tag + age, independent of whether `destroy` ran.

---

## Versioning dependency

- Repo-wide **semver**. Full versioning/release strategy is a **separate doc (to be written)**.
- Stage 2 needs a "latest release" to diff against, so the tag scheme must exist **before Stage 2 is built** (not before Stage 1).
- **1.0.0 should be cut on validated code** — i.e., the first tag that has passed Tier 0 + Stage 1 — not on the current untested state.

---

## Build sequence

1. **Tier 0** static checks across all modules (cheap, immediate value, zero Azure cost).
2. **Pilot `public_ip`** end-to-end through Stage 1 (proves fixtures, naming, state, idempotency, baseline mechanism).
3. **Reusable-workflow / composite-action wrapper** (design genericity in, not retrofit).
4. **Pilot `application_gateway`** to prove real-sibling wiring (`public_ip` + `web_application_firewall_policy`).
5. **Expand examples** module-by-module, fastest → slowest (APIM / App Gateway / Cosmos last).
6. **Stage 2** (after versioning strategy + first release exist).
7. **Janitor + soft-delete purge** built alongside step 5 (leaks start as soon as real deploys run).

---

## Open / deferred items

- **Versioning & release strategy** — see [versioning-strategy.md](versioning-strategy.md). Stage 2 depends on a released tag to diff against, and the release pipeline reuses this doc's `.tf`-only folder-diff logic to stamp each module's `metadata.yaml` (`module_last_changed`). The first `1.0.0` tag is cut only after Tier 0 + Stage 1 validate the modules.
- Final backend/state cleanup approach for crashed runs (local vs. remote recoverability) — currently remote state + janitor.
- Exact `tflint`/security-scanner selection for Tier 0.
