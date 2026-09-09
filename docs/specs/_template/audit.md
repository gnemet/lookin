# <Feature> — Security / Rules Audit (<date>)

> Adversarial review against the platform rules (`security_and_hardening.md`,
> `database_and_sql.md`, `languages_and_standards.md`, `environment_and_config.md`).
> Ideally run by the `security-reviewer` agent. Each finding: what, severity,
> resolution (or accepted residual risk + why).

## Findings & resolutions
| # | Finding | Severity | Resolution |
|---|---|---|---|
| 1 | <finding> | high/med/low | <fixed in … / accepted because …> |

## Verification & acceptance — dual sign-off (A9)
> "Done" passes two human gates: **verification** (built it right) and **validation/acceptance** (built the right thing). Each requirement row is signed off by **both** the code/architecture reviewer and the QA acceptance owner.

| Req | Mechanism | Verified how (build/test/smoke) | Accepted how (journey + performance) | Code reviewer | QA acceptance owner | Status |
|---|---|---|---|---|---|---|
| U1/E1 | <design mechanism> | <test / smoke> | <user journey + SLA met> | <name> | <name> | ⬜ / 🟡 / ✅ |

## Accepted residual risk
<Risks knowingly accepted for this release, with the trust assumption that makes them acceptable.>
