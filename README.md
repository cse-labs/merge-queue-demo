# Merge Queue Demo

This folder contains Proof of Concept files to demonstrate GitHub Merge Queues.

## Files

- `.github/workflows/merge-queue-demo.yaml`: A GitHub Actions workflow configured to run on `pull_request` and `merge_group` events.
- `test.sh`: A script that simulates test execution with various modes (`pass`, `fail`, `flaky`, `sleep`).
- `version.txt`: A simple text file used to demonstrate semantic conflicts.

## Usage

1. **Setup**:
   - Ensure `test.sh` is executable (`chmod +x scripts/test.sh`).

## Scenarios

### 1. Happy Path

- **Action**: Create a PR with no changes to the POC files (or trivial changes).
- **Expectation**: All checks pass. Add to merge queue. It merges successfully.

### 2. Simple Failure

- **Action**: Modify `merge-queue-demo.yaml` in your PR to run `./scripts/test.sh fail`.
- **Expectation**: The PR check fails immediately. You cannot add it to the merge queue.

### 3. Merge Queue Exclusive Failure

- **Action**:

  - Modify `merge-queue-demo.yaml` to make the `merge-queue-exclusive` job fail:

    ```yaml
    merge-queue-exclusive:
      if: github.event_name == 'merge_group'
      steps:
        - run: ./scripts/test.sh fail
    ```

- **Expectation**:
  - PR checks pass (because this job is skipped on `pull_request`).
  - You add it to the merge queue.
  - The job runs in the queue and fails.
  - The PR is removed from the queue.

### 4. Flaky Tests

- **Action**:

  - Modify `merge-queue-demo.yaml` to use the `flaky` mode:

    ```yaml
    flaky-test:
      steps:
        - run: ./scripts/test.sh flaky
    ```

- **Expectation**:
  - The test will fail ~50% of the time.
  - Observe how the Merge Queue handles retries (if configured) or failures.

### 5. Semantic Conflict (The "Diamond Dependency" / Logical Conflict)

This scenario simulates two PRs that pass individually but fail when combined.

- **Setup**: Ensure `scripts/test.sh` is in `main`.
- **PR A**:
  - Update `scripts/test.sh` to **require** an argument.
  - Change line 4 to: `MODE="${1:?Usage: test.sh <mode>}"`
  - Update `merge-queue-demo.yaml` in PR A to pass an argument (e.g., `./scripts/test.sh pass`).
  - **Result**: PR A passes checks.
- **PR B**:
  - Add a new step to `merge-queue-demo.yaml` that calls `./scripts/test.sh` **without** arguments.
  - **Result**: PR B passes checks (because in PR B's context, `test.sh` is still the old version that defaults to "pass").
- **Execution**:
  1. Add PR A to the merge queue.
  2. Add PR B to the merge queue immediately after.
  3. PR A merges.
  4. PR B runs in the queue _on top of_ PR A's changes.
  5. PR B's new step calls `test.sh` (which is now the version from PR A).
  6. `test.sh` fails because it requires an argument.
  7. **Result**: PR B fails in the merge queue and is removed.

### 6. Version Conflict

- **PR A**: Change `scripts/version.txt` to `1.1.0`.
- **PR B**: Change `scripts/version.txt` to `1.2.0`.
- **Result**: If git cannot auto-resolve, this is a standard merge conflict. If they touch different lines (e.g., appending to a log), both might merge, but a test checking for specific content would fail in the queue.
