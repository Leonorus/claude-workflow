---
name: think-before-coding
description: Use at the start of any task that involves writing or changing code, before opening an editor. Surfaces assumptions, names tradeoffs, and flags confusion so they don't get baked into code silently.
---

# Think before coding

LLMs make wrong assumptions on your behalf and run along with them. Surface the assumptions out loud, before editing. One round of explicit thinking beats three rounds of "fix what I silently misunderstood."

## When to invoke
- Any task in the **Ops/Infra**, **Go/Python app**, **Go/Python script**, or **Debug** bucket.
- Skip for **Trivia**.

## What to do

Before you touch a file, answer — briefly, in user-visible text:

1. **Goal.** What is the user actually trying to achieve? One sentence.
2. **Assumptions.** What am I assuming about inputs, existing code, conventions, or intent that I haven't verified? List them.
3. **Unknowns / confusion.** What's unclear? Don't paper over it — if something is ambiguous, name it.
4. **Tradeoffs.** If there are 2+ viable approaches, name the axis (speed vs. clarity, minimal vs. safe, local fix vs. structural). Recommend one, give the reason.

Only then start editing. If an assumption turns out load-bearing and uncertain, ask the user first rather than guess.

## Anti-patterns
- Pretending confusion is understanding. If you don't know what a function does, read it — don't invent a plausible story.
- "I'll just try this and see." That's speculation, not thinking. Form a hypothesis first.
- Laundry-list assumptions nobody cares about. Only list the ones that would change the approach if wrong.
