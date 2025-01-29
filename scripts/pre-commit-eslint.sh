#!/bin/sh

# 1. Check if `eslint` is installed (on the PATH)
if ! command -v eslint >/dev/null 2>&1; then
  echo "ESLint not found, skipping lint step."
  # Either exit successfully (so the commit proceeds)
  exit 0

  # OR exit with a non-zero status if you want to block the commit:
  # echo "Please install ESLint before committing."
  # exit 1
fi

echo "Running ESLint..."

# 2. Proceed with linting your staged files
STAGED_JS=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|jsx|ts|tsx)$')
if [ -z "$STAGED_JS" ]; then
  echo "No JS/TS files staged. Skipping ESLint."
  exit 0
fi

# 3. Use whatever ESLint command you like here
eslint --no-eslintrc -c ~/eslint.config.js $STAGED_JS --fix
if [ $? -ne 0 ]; then
  echo "Lint errors found! Aborting commit."
  exit 1
fi

exit 0
