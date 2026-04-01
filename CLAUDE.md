@README.md

# KindleAPI — Swift Kindle Web Scraping Library

## Project Map

```
Sources/KindleAPI/
├── KindleAPI.swift              Main API interface
├── KindleEndpoint.swift         Endpoint definitions
├── KindleError.swift            Error types
├── KindleLogger.swift           Logging
├── Utils.swift                  Helpers
├── Authentication/
│   └── KindleAuthentication.swift   Session management
└── Models/
    ├── KindleHTMLBook.swift     Book data from HTML scraping
    ├── KindleJSONBook.swift     Book data from JSON endpoints
    └── KindleAnnotation.swift   Highlights/notes from HTML

Tests/KindleAPITests/
└── KindleAPITests.swift         Unit tests
```

## Build & Test

```bash
swift build
swift test
```

## Tech Stack

- **Language:** Swift 5.9+
- **Platforms:** iOS 17+, macOS 14+, macCatalyst 17+
- **Dependencies:** SwiftSoup (HTML parsing)
- **Type:** Swift Package (library)

## Architecture

- **KindleAPI** — main entry point, fetches books and annotations from Kindle
- **KindleEndpoint** — URL construction for Kindle web endpoints
- **Models** — separate structs for HTML-scraped vs JSON book data
- **Authentication** — session/cookie management for Kindle web access

This is a standalone, cross-platform Swift package. It is used as a git submodule in the Scrapes app but should remain independent and reusable.

# Multi-agent Work Environment

## How It Works

1. The user describes the work
2. The lead agent reads it
3. The lead agent decomposes the project into a phased task plan
4. The lead agent spawn workers agents via the `Agent` tool to execute tasks in parallel
5. Builder workers build code, write tests, and commit their work, all in independent worktrees
6. Reviewer agents review, request changes, and keep a consistent, high quality bar in the project
7. The lead agent coordinates work, works with the user, keeps `main` up to date, moves tasks to `in-progress` and `done`, merges pull requests, and executes any other requests on behalf of the user.

## Lead Agent Behavior

The user will first discuss high level plan with you. Once the user confirms we're good to start work:

1. **Read** `README.md` and other top-level docs to understand the project
2. **Plan** — Break the project into phases and tasks:
   - **Phase 0: Bootstrap** — Project scaffolding, directory structure, config files, dependency setup
   - **Phase 1: Core** — Core data models, types, interfaces
   - **Phase 2: Implementation** — Feature implementation (parallelize heavily here)
   - **Phase 3: Integration** — Wire components together, integration tests
   - **Phase 4: Polish** — Error handling, edge cases, documentation, final tests
3. **Create tasks** using `TaskCreate` for each work item, with:
   - Clear subject (imperative: "Implement user authentication endpoint")
   - Detailed description with acceptance criteria, file paths, and dependencies
   - `activeForm` in present continuous ("Implementing user authentication")
   - Dependency chains via `addBlockedBy` (Phase 1 tasks block on Phase 0, etc.)
   - List of edge cases that are covered, and edge cases that are not important.
4. **Spawn workers** using the `Agent` tool with `subagent_type: "general-purpose"`
   - Spawn 3-6 workers depending on project complexity
   - Use the best model available to you with the maximum effort
   - Pass the task ID and full task details explicitly in each worker's `prompt`
   - Name them descriptively in the description: `builder-1`, `builder-2`, `reviewer-1`, `reviewer-2`, `tester`, etc.
   - Generally prefer reviewers to have larger context and bigger models
   - Keep the main checkout on `main` branch and `git pull --ff` after each task is completed and merged
5. **Assign tasks** to idle workers as they become available
6. **Track task file state** — move task files between directories to reflect their status:
   - When a worker claims a task: `mv tasks/backlog/<task>.md tasks/in-progress/`
   - When a task's PR is merged and verified: `mv tasks/in-progress/<task>.md tasks/done/`
   - This keeps the file system in sync with actual task status at all times
7. **Monitor progress** — poll `TaskList`/`TaskGet` to track worker progress; spawn the next worker when one completes
8. **Assign reviews of pull requests**. Once a worker prepares a task implementation in a pull request, assign a task to review this pull request to one of the reviewer agents

- Reviewers post their feedback on GitHub pull request comments
- Builder addresses all feedback
- You ask for a review again
- After successful and clean review, you make a decision to merge

9. **Handle conflicts** — if workers produce conflicting changes, you will ask builders to review and resolve conflicts in their respective pull requests
10. **Shut down** when all tasks are complete

## Worker Agent Instructions

Workers are spawned by the lead via the `Agent` tool. The lead passes the task ID and description in the prompt. Each worker MUST:

1. **Read the task** with `TaskGet <task-id>` to get full requirements
2. **Mark it in-progress** with `TaskUpdate`
3. **Create a git worktree** — ALWAYS use a worktree, never work in the main checkout:

   ```bash
   git fetch origin && git pull --ff   # in main checkout first
   git worktree add ../worktrees/swift-kindle-task-N -b task-N-description
   cd ../worktrees/swift-kindle-task-N
   ```

   - Each task gets its own worktree and its own branch
   - Branch off the latest `main`
   - Work exclusively inside the worktree directory

4. **Read existing code** before writing — understand the current state
5. **Implement the task** — write code, tests, configs as needed
6. **Verify the work** — run the project's quality checks:
   - `swift build` — builds cleanly
   - `swift test` — all tests pass
- You are _required_ to have a strong suite of tests that follows Swift testing best practices.
- You are _required_ to fix all build warnings and errors before committing.

7. **Commit the work** with a descriptive message (include task ID):
   - Format: `[task-N] <description>`
   - One logical change per commit
8. **Push and create a pull request** — MANDATORY for every task with code changes:

   ```bash
   git push -u origin task-N-description
   gh pr create --title "type(feat/doc/chore/ref) [task-N] description" --body "..."
   ```

   - Every code change goes through a PR. No direct commits to `main` are allowed.

9. **Update the task** via `TaskUpdate` with PR URL and status, so the lead knows to assign a reviewer
10. **Respond to review comments**, push fixes, then merge the PR. You are required to resolve all review feedback, unless it introduces security problems that the reviewer did not catch.
11. **Wait for the Leader to confirm successful Merge**.
12. **Clean up the worktree** after merge:
    ```bash
    cd /Users/natikgadzhi/src/natikgadzhi/scrapes/Packages/KindleAPI
    git worktree remove ../worktrees/swift-kindle-task-N
    ```
13. **Mark the task completed** with `TaskUpdate` (status: completed)

## Reviewer Agent Instructions

Reviewers are spawned by the Lead agent with the PR number and task ID in their prompt.

1. **Check out the PR branch** in a worktree:
   ```bash
   git worktree add ../worktrees/swift-kindle-review-N origin/task-N-description
   cd ../worktrees/swift-kindle-review-N
   ```
2. **Check for conflicts** — ensure the branch rebases cleanly on latest `main`. If conflicts exist, flag them and request the worker to rebase.
3. **Run all quality checks**:
   - `swift build` — builds cleanly
   - `swift test` — all tests pass (including new tests for the feature)
4. **Verify the feature works** — read the task description and acceptance criteria, confirm the implementation satisfies each criterion
5. **Code quality review**:
   - Use `/simplify` Claude skill / agent
   - Read every changed file in the diff (`gh pr diff`)
   - Check for dead code, unnecessary complexity, or missing error handling
   - Verify naming conventions and code style match the rest of the codebase
   - Ensure no commented-out code was left behind
6. **Security review**:
   - Ensure secrets and tokens are not logged or exposed
   - Check that user input is validated at system boundaries
7. **Post a PR review** via `gh pr review` with:
   - Summary of what was reviewed
   - Edge cases that ARE covered
   - Edge cases NOT covered (note whether they should be addressed now or later)
   - Any security concerns
   - Approve, request changes, or comment accordingly
8. **Clean up the worktree** after review:
   ```bash
   cd /Users/natikgadzhi/src/natikgadzhi/scrapes/Packages/KindleAPI
   git worktree remove ../worktrees/swift-kindle-review-N
   ```
9. **Update the task** via `TaskUpdate` with the review outcome

## Git Conventions

- The main checkout stays on `main`. Never switch branches here — workers use worktrees.
- Do `git pull --ff` after every task is completed and merged.
- Each task branch is based off the latest `main`.
- Every code change goes through a PR — no direct commits to `main`.
- Workers commit with messages: `[task-N] <description>`
- One logical change per commit — don't bundle unrelated work
- Workers should `git pull --rebase` before pushing to avoid conflicts

## Task File System

Tasks are stored as markdown files in `tasks/` with three subdirectories representing status:

```
tasks/
├── backlog/      # Not yet started
├── in-progress/  # Currently being worked on
└── done/         # Completed and merged
```

- Each task is a numbered markdown file (e.g. `01-refactor-endpoint-parsing.md`)
- The lead agent creates task files in `backlog/` during planning
- Workers move their task file to `in-progress/` when they start work
- Workers move their task file to `done/` after the PR is merged and the task is complete
- Task files contain the full specification: objective, acceptance criteria, dependencies, and notes
- Moving task files between directories should be committed as part of the worker's branch

## Important Rules

- **Always fetch before checking task status** — run `git fetch` and `git pull --ff` before answering questions about whether a task is done, what's been merged, or what state the codebase is in.
- **Always read before writing** — understand existing code before changing it
- **Test everything** — write tests for every task. If ambiguous what kind, ask the user
- **Small, focused tasks** — each task should be completable in one agent session
- **Explicit dependencies** — if task B needs task A's output, declare it with `addBlockedBy`
- **No premature abstraction** — build what's needed, not what might be needed
- **Commit early and often** — small atomic commits, not monolithic ones
- **Always verify with end-to-end tests** — business logic correctness matters, not just code presence
- **Keep cross-platform** — this library should work on all Apple platforms, avoid UIKit/AppKit dependencies
