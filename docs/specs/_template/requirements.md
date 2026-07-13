# <Feature> — Requirements (EARS)

> The **what**. Behavioral invariants, one constrained testable clause each, in
> EARS form. Business **why** → `brief.md` (tag each req with its goal `G#`).
> Enforcement → `design.md`. Open work → `tasks.md`.
>
> Patterns: **U** Ubiquitous (always) · **E** Event (When …) · **S** State
> (While …) · **X** Unwanted (If … then …) · **O** Optional (Where … enabled).
> Status: `[x]` verified · `[~]` partial · `[ ]` planned.
>
> EARS shapes (copy one):
> - Ubiquitous:  *The <system> **shall** <response>.*
> - Event:       ***When** <trigger>, the <system> **shall** <response>.*
> - State:       ***While** <state>, the <system> **shall** <response>.*
> - Optional:    ***Where** <feature included>, the <system> **shall** <response>.*
> - Unwanted:    ***If** <condition>, **then** the <system> **shall** <response>.*

## U — Ubiquitous
- **U1** `[ ]` (G?) The <system> **shall** <response>.

## E — Event-driven
- **E1** `[ ]` (G?) **When** <trigger>, the <system> **shall** <response>.

## S — State-driven
- **S1** `[ ]` (G?) **While** <state>, the <system> **shall** <response>.

## X — Unwanted behavior
- **X1** `[ ]` (G?) **If** <condition>, **then** the <system> **shall** <response>.

## O — Optional / conditional
- **O1** `[ ]` (G?) **Where** <feature enabled>, the <system> **shall** <response>.
