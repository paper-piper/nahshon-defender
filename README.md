# Nahshon Defender

A Git pre-commit hook system that enforces strict rules on `.txt` files committed to this repository. Every commit is automatically validated — invalid commits are blocked with a clear error message before they ever touch the history.

---

## Rules

Every `.txt` file staged for a commit must satisfy all four rules:

| Rule | Description |
|------|-------------|
| **Filename** | The filename must be a positive integer with a `.txt` extension. `1.txt`, `2.txt`, `46.txt` are valid. `0.txt`, `01.txt`, `1.5.txt`, `notes.txt` are not. |
| **Structure** | Files must live directly inside a version folder at the repo root. The version folder must match `V_N.N.N` (single digit per component). `V_1.2.3/7.txt` is valid. `loose.txt`, `V_1.0.0/sub/1.txt`, and `V_12.3.4/1.txt` are not. |
| **Content** | No line may begin with the lowercase word `delete`. `Delete` and `DELETE` are allowed; `delete` is not. |
| **Append-only** | Once a file is committed, its existing lines may never be changed or removed. You may only add new lines at the end. |

Additionally, `.txt` files **may not be deleted** once they have been committed.

---

## Project Structure

```
.githooks/
  pre-commit              # Main hook — runs all validators on every commit
  lib/
    validate_filename.sh  # Enforces the filename rule
    validate_content.sh   # Enforces the content rule
    validate_structure.sh # Enforces the structure rule
    validate_append_only.sh # Enforces the append-only rule
scripts/
  setup.sh                # One-time setup: configures Git to use .githooks/
  test_hooks.sh           # Test suite for all validators
V_4.3.2/                  # Example version folder with committed .txt files
```

---

## Setup

Run once after cloning:

```sh
sh scripts/setup.sh
```

This points Git's hook lookup at the version-controlled `.githooks/` directory so the pre-commit hook runs automatically on every `git commit`.

---

## Example

**Valid commit — allowed:**
```
V_1.0.0/
  1.txt   ← positive integer filename ✓
  2.txt   ← positive integer filename ✓
```

**Invalid commit — blocked:**
```
V_1.0.0/notes.txt   ← filename is not a number
V_10.0.0/1.txt      ← version component has more than one digit
1.txt               ← no version folder
```

When a commit is blocked, the hook prints exactly which rule failed and why:

```
BLOCKED [filename]     V_1.0.0/notes.txt
  > Basename must be a positive integer with a .txt extension.
  > Valid examples:   1.txt  2.txt  46.txt
  > Invalid examples: 0.txt  01.txt  1.5.txt  notes.txt

Commit aborted — fix the errors listed above and try again.
```

---

## Running the Tests

```sh
sh scripts/test_hooks.sh
```

The test suite can be run from any directory. It covers valid and invalid cases for every rule and prints a pass/fail result for each, followed by a summary. The repo is left in exactly the same state as before the tests ran.
