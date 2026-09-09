# <Feature> — Tests (TDD)

> The **proof, written first**. Each mechanism in `design.md` is defined here by the test that fails
> before it exists, and **the test is committed red before the code it constrains**. Review reads
> the test as well as the diff; weakening an assertion is a spec change, not a fix.
> Discipline → `docs/rules/03_testing_verification/testing_and_verification.md § Test-first (TDD)`.
>
> Tiers: **T1** static (no external dependency) · **T2** hermetic (throwaway DB / local run, egress
> blocked) · **T3** contract (a live dependency). **Assert values and counts, never "no error".**

## The red-first order

| # | Test | Tier | Asserts | Red until | Req |
|---|---|---|---|---|---|
| **TS1** | <what it pins down> | T1/T2/T3 | <the value or count, not "it ran"> | T<n> | U1, E1 |

## What a green suite still does not prove

<Everything above is verification — "built it right". Name the acceptance gate (a task in
`tasks.md`) that answers "built the right thing", and say plainly what a fully green suite does
not yet demonstrate.>

## Writing rules for this suite

- Assert counts and values, never absence of error — `exit 0` is not a result.
- A test needing the network is T3 and says so; T1/T2 run with egress blocked.
- Seed fixtures through the same stored functions the app calls — a fixture written by inline DML
  tests a shape the application can never produce.
