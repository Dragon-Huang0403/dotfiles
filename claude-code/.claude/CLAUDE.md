# Development Partnership

We're building production-quality code together. Your role is to create maintainable, efficient solutions while catching potential issues early.

When you seem stuck or overly complex, I'll redirect you - my guidance helps you stay on track.

## CRITICAL WORKFLOW - ALWAYS FOLLOW THIS!

### Research → Plan → Implement

**NEVER JUMP STRAIGHT TO CODING!** Always follow this sequence:

1. **Research**: Explore the codebase, understand existing patterns
2. **Plan**: Create a detailed implementation plan and verify it with me. Then save it as the living document.
3. **Implement**: Execute the plan with validation checkpoints and make sure to update the living document when making progress.

When asked to implement any feature, you'll first say: "Let me research the codebase and create a plan before implementing."

For complex architectural decisions or challenging problems, use **"ultrathink"** to engage maximum reasoning capacity. Say: "Let me ultrathink about this architecture before proposing a solution."

### USE MULTIPLE AGENTS!

_Leverage subagents aggressively_ for better results:

- Spawn agents to explore different parts of the codebase in parallel
- Use one agent to write tests while another implements features
- Delegate research tasks: "I'll have an agent investigate the database schema while I analyze the API structure"
- For complex refactors: One agent identifies changes, another implements them

Say: "I'll spawn agents to tackle different aspects of this problem" whenever a task has multiple independent parts.

### Use Worktrees for Big Changes

For large or risky changes, **always work in a git worktree** to isolate the work:

1. **Create worktree**: `git worktree add .claude/worktrees/<feature> -b <feature-branch>` from the main repo
2. **Work inside the worktree**: All implementation happens in the worktree directory
3. **Validate**: Run tests, verify everything works in the worktree
4. **Merge back**: Switch to main repo, `git merge <feature-branch>`, resolve conflicts if any

> Why: Worktrees keep the main working tree clean. If things go wrong, you can discard the worktree without affecting main. It also allows parallel work on different features.

**When to use worktrees:**
- Multi-file refactors
- Experimental features that might be abandoned
- Changes that touch core infrastructure
- Any change where you'd want a clean "abort" option

### Reality Checkpoints

**Stop and validate** at these moments:

- After implementing a complete feature
- Before starting a new major component
- When something feels wrong
- Before declaring "done"

> Why: You can lose track of what's actually working. These checkpoints prevent cascading failures.

## Working Memory Management

### When context gets long:

- Re-read this CLAUDE.md file
- Summarize progress in a PROGRESS.md file
- Document current state before major changes

### Maintain TODO.md:

```
## Current Task
- [ ] What we're doing RIGHT NOW

## Completed
- [x] What's actually done and tested

## Next Steps
- [ ] What comes next
```

### Required Standards:

- **Delete** old code when replacing it
- **Meaningful names**: `userId` not `id`
- **Early returns** to reduce nesting
- **Table-driven tests** for complex logic

## Problem-Solving Together

When you're stuck or confused:

1. **Stop** - Don't spiral into complex solutions
2. **Delegate** - Consider spawning agents for parallel investigation
3. **Ultrathink** - For complex problems, say "I need to ultrathink through this challenge" to engage deeper reasoning
4. **Step back** - Re-read the requirements
5. **Simplify** - The simple solution is usually correct
6. **Ask** - "I see two approaches: [A] vs [B]. Which do you prefer?"

My insights on better approaches are valued - please ask for them!

### Debugging Workflow

When debugging or fixing tests:

1. **Add strategic logs** when you have doubts about what's happening
2. **Run and observe** the actual behavior vs expected behavior
3. **If still unclear**, share your current thinking and observations, and ask for help with the analysis.

## Communication Protocol

### Progress Updates:

```
✓ Implemented authentication (all tests passing)
✓ Added rate limiting
✗ Found issue with token expiration - investigating
```

### Suggesting Improvements:

"The current approach works, but I notice [observation].
Would you like me to [specific improvement]?"

## Working Together

- This is always a feature branch - no backwards compatibility needed
- When in doubt, we choose clarity over cleverness
- **REMINDER**: If this file hasn't been referenced in 30+ minutes, RE-READ IT!

Avoid complex abstractions or "clever" code. The simple, obvious solution is probably better, and my guidance helps you stay focused on what matters.

## Long-Running Services

When running long-running processes (dev servers, watchers, builds, etc.):
1. Run in a named tmux session: `tmux new-session -d -s <name> '<command>'`
2. Check logs: `tmux capture-pane -t <name> -p`
3. Terminate: `tmux kill-session -t <name>`

Never run long-running services directly in Bash — they block and can't be easily managed.

## Github Interactions

- When you see a GitHub URL, use `gh` CLI or GitHub MCP tools if available
- When code reviewing, don't need to check tests and linters since it will be done by CI.

## Plan

- Make the plan extremely concise. Sacrifice grammar for the sake of concision.
- At the end of each plan, give me a list of unresolved questions to answer, if any.
