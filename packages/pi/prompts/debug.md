---
description: Debug a crash or error with tmux for live reproduction
---
Debug a crash, error, or unexpected behavior. Use tmux to run the failing code
live alongside this session.

$@

If the issue was described above, use that description. Otherwise ask the user to
describe the problem.

## Debugging Workflow

Use this workflow when debugging runtime issues:

### Step 1: Set Up tmux Split

Split your current tmux session so you can run the failing code while
communicating here:

```bash
# Split horizontally (code below, chat above)
tmux split-window -v

# Or split vertically (code on right, chat on left)
tmux split-window -h
```

### Step 2: Prepare the Debug Environment

In the new tmux pane, prepare to run the failing code:

1. **Enable debug output** — set environment variables:
   ```bash
   # Node.js
   export DEBUG=*

   # Python
   export PYTHONDEBUG=1
   # or
   python -m pdb script.py

   # Rust
   export RUST_BACKTRACE=full
   cargo run ...
   ```

2. **Navigate to the correct directory** if needed

3. **Have the exact command ready** to reproduce the issue

### Step 3: Wait for Reproduction

Tell the user: *"I'm ready. Please trigger the issue in the split pane."*

Wait for them to reproduce the crash or error.

### Step 4: Analyze the Output

Once the user has reproduced the issue, examine:

1. **Stack trace** — identify the failing line and call stack
2. **Error message** — understand what went wrong
3. **Debug output** — trace the data flow that led to the failure
4. **Context** — read the surrounding code to understand the bug

### Step 5: Diagnose and Fix

After analyzing:

- **Identify the root cause** — not just the symptom
- **Propose a fix** — explain why it will work
- **Suggest verification** — how to confirm the fix

## Common Debug Patterns

### Unhandled Exception / Crash

```
1. Run with full backtrace (RUST_BACKTRACE=full, --trace-errors, etc.)
2. Read the stack trace from bottom to top
3. Find the first line in your code (not a library)
4. Examine that function and its callers
```

### Logic Error / Wrong Output

```
1. Add debug logging at key points
2. Print variable values at decision points
3. Trace the data flow step by step
4. Find where actual diverges from expected
```

### Race Condition / Intermittent Failure

```
1. Enable debug logging for concurrent operations
2. Look for timing-related output
3. Check shared state and mutation points
4. Consider adding synchronization or atomic operations
```

### Memory Issue (Leak, Corruption)

```
1. Run with memory debugging tools (valgrind, AddressSanitizer)
2. Look for allocation/deallocation mismatches
3. Check for dangling pointers
4. Review lifetime management
```

## Tmux Reference

| Action | Command |
|--------|---------|
| Split horizontal | `tmux split-window -v` |
| Split vertical | `tmux split-window -h` |
| Switch panes | `Ctrl+b o` |
| Resize pane | `Ctrl+b : resize-pane -D/-U/-L/-R` |
| Close pane | `Ctrl+b d` (detach) or `exit` |
| List panes | `tmux list-panes` |
| Scroll buffer | `Ctrl+b [` then arrow keys |

## Rules

- Do not run the reproduction command yourself — let the user trigger it
- Wait for confirmation that the issue has reproduced before analyzing
- Be specific about line numbers and variable states
- If the issue is not reproducible, suggest how to make it deterministic
- Do not modify files unless the user explicitly asks for a fix
