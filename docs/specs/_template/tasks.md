# <Feature> — Tasks

> The **work**. Sequenced with dependencies. Closing a task means: the named
> mechanism exists, its **verification** passes (build/test/smoke + code review),
> **and** its **acceptance** passes (QA accepts against the goal). When
> done, flip the matching status in `requirements.md` and `design.md`.
>
> **Test-first (TDD).** Each task names the tests from `tests.md` that define it; those tests are
> written and committed **red, before** the mechanism. Start the task list with the task that
> commits the red suite.

## Status (<date>)
<1–3 sentences: what's built + verified vs pending.>

| Task | State |
|---|---|
| T1 <title> | ⬜ / 🟡 / ✅ |

## Open tasks
| ID | Req | Task | Depends on |
|---|---|---|---|
| **T1** | U1, E1 | <what to build> | — |
| **Tn** | <Req> | Acceptance + performance test: walk the real end-user journey, run the load benchmark against the SLA, QA sign-off | <impl tasks> |

## Verification — end-to-end acceptance
<The single scenario that proves the feature works for a real user.>
<Include the performance acceptance: the SLA (latency/throughput/load) and how the QA judges pass/fail — AI runs the benchmark, QA accepts.>
