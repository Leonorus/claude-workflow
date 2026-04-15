---
name: goal-driven-execution
description: Use for any task with a definable success criterion, before claiming work is complete. Define what "done" means in verifiable terms up front, then loop until the criterion passes. No completion claims without evidence.
---

# Goal-driven execution

LLMs are good at looping until a specific goal is met. Bad at self-assessing when a goal is vague.

Define the goal in verifiable terms. Run the check. Repeat until green. Then — and only then — claim done.

## When to invoke
- Every non-trivia bucket. Especially during **Debug** and **Go/Python app** work.
- Before saying "done", "fixed", "works", "passes", or "ready to commit".

## The contract

1. **Write down what done looks like.** One or two concrete, checkable criteria. Examples:
   - "`go test ./...` passes with zero failures"
   - "`ansible-playbook --check site.yml` reports no changed tasks on a second run"
   - "request to `/healthz` returns 200 with body `{\"ok\":true}`"
   - "the bug from the issue report no longer reproduces with command X"

2. **Run the check.** Actually execute it. Don't infer from code reading.

3. **Read the output.** Not "it ran", but "it produced the expected output". Paste or quote the relevant line in your summary.

4. **Loop if needed.** If the check failed, fix, re-run. Do not move on until the check passes.

5. **Report with evidence.** When claiming done, cite the command and the output line that proves it.

## Anti-patterns
- "Should work now" — no check was run.
- "The tests pass" — no command shown. Show the command *and* its output line.
- Silently skipping a verification because it's slow. Say so; propose a faster alternative.
- Reading code to "verify" dynamic behavior. Code reading is not execution.
- Claiming done when some criteria pass but a known one fails. Report the failure.
