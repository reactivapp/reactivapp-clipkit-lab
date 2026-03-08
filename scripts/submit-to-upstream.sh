#!/usr/bin/env bash
# Clone a separate repo, create a branch, copy this repo's contents into it, then open a PR.
#
# Usage:
#   TARGET_REPO_URL=https://github.com/org/repo.git BRANCH_NAME=submission/scanify ./submit-to-upstream.sh
#   ./submit-to-upstream.sh  # uses defaults below
#
# Prereq: You must be able to push to TARGET_REPO_URL (e.g. your fork of reactivapp-clipkit-lab).

set -e

# Defaults: Reactiv ClipKit Lab upstream. Replace with your fork URL if you need to push.
TARGET_REPO_URL="${TARGET_REPO_URL:-https://github.com/reactivapp/reactivapp-clipkit-lab.git}"
BRANCH_NAME="${BRANCH_NAME:-submission/scanify}"
CLONE_DIR="${CLONE_DIR:-}"

# This repo's root (where the script lives) -> parent dir for clone
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PARENT_DIR="$(dirname "$SOURCE_ROOT")"

if [[ -z "$CLONE_DIR" ]]; then
  # Default: clone into sibling directory named after repo
  REPO_NAME="$(basename "$TARGET_REPO_URL" .git)"
  CLONE_DIR="$PARENT_DIR/$REPO_NAME"
fi

echo "Source repo (this one):  $SOURCE_ROOT"
echo "Target repo URL:         $TARGET_REPO_URL"
echo "Clone directory:        $CLONE_DIR"
echo "Branch name:            $BRANCH_NAME"
echo ""

if [[ -d "$CLONE_DIR" ]]; then
  echo "Directory $CLONE_DIR already exists."
  read -p "Use it as-is and only run branch + copy (y/N)? " use_existing
  if [[ "${use_existing,,}" != "y" ]]; then
    echo "Aborted. Remove or rename $CLONE_DIR and run again, or set CLONE_DIR to a different path."
    exit 1
  fi
  cd "$CLONE_DIR"
  git fetch origin
  git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"
else
  echo "Cloning into $CLONE_DIR ..."
  git clone "$TARGET_REPO_URL" "$CLONE_DIR"
  cd "$CLONE_DIR"
  git checkout -b "$BRANCH_NAME"
fi

echo ""
echo "Copying this repo's contents into the branch (excluding .git and a few paths) ..."

# Copy everything from source into clone, excluding .git and common noise
rsync -a --delete \
  --exclude='.git' \
  --exclude='.gitignore' \
  --exclude='.DS_Store' \
  --exclude='PR_WORKFLOW.md' \
  --exclude='*.xcuserstate' \
  --exclude='DerivedData' \
  "$SOURCE_ROOT/" "$CLONE_DIR/"

echo "Done copying."
echo ""
echo "Next steps (run these yourself):"
echo "  cd $CLONE_DIR"
echo "  git status"
echo "  git add -A"
echo "  git commit -m \"Add Scanify submission\""
echo "  git push -u origin $BRANCH_NAME"
echo ""
echo "Then open a PR:"
echo "  If you pushed to your fork, go to GitHub and open a Pull Request from branch $BRANCH_NAME to the upstream default branch."
echo "  Direct link (replace YOUR_FORK with your GitHub username if you use a fork):"
echo "  https://github.com/reactivapp/reactivapp-clipkit-lab/compare/main...YOUR_FORK:reactivapp-clipkit-lab:$BRANCH_NAME?expand=1"
echo ""
echo "Or create the PR from the fork’s repo page after pushing."
