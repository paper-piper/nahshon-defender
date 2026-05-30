#!/usr/bin/env sh

git config core.hooksPath .githooks # Redirect Git's hook lookup to our version-controlled directory.
chmod +x .githooks/pre-commit # Guarantee the hook is executable.
# chmod - change mode. +x - add execute permission for all users.