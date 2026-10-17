#!/usr/bin/env bash
# Run by the pipeline on the server, over SSH, at the start of each
# deploy: brings the repository to the commit being deployed. The first
# time, it clones the repository. Then, and whenever setup-ubuntu.sh
# changes, it prepares the server with it (Docker, the firewall, .env,
# backups).
#
#   ssh server bash -s -- <folder> <branch> <commit> <repository> < deploy/checkout.sh
set -euo pipefail
dir="$1" branch="$2" commit="$3" repo="$4"
[[ "$dir" == /* ]] || dir="$HOME/$dir"

# GitHub's SSH host key (published at https://api.github.com/meta), so a
# first clone over SSH does not stop to ask about it.
if ! ssh-keygen -F github.com >/dev/null 2>&1; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  echo 'github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' \
    >> ~/.ssh/known_hosts
fi

if [[ ! -d "$dir/.git" ]]; then
  echo "== Cloning $repo into $dir"
  git clone -q --branch "$branch" "$repo" "$dir"
fi
cd "$dir"

# Changes made by hand on the server would mix with the release: stop.
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  echo "The code in $dir was changed on the server:" >&2
  git status --short --untracked-files=no >&2
  echo "Push those changes to GitHub, or discard them with: git -C $dir checkout -- ." >&2
  exit 1
fi

echo "== Checking out $commit ($branch)"
git fetch --prune origin "+refs/heads/$branch:refs/remotes/origin/$branch"
git checkout -q -B "$branch" "$commit"
git branch -q --set-upstream-to "origin/$branch"
git log -1 --format='   %h %s'
# Made here, not by Docker, so the pipeline can upload the app into it.
mkdir -p frontend/build/web

# setup-ubuntu.sh records which version of itself last ran; run it on
# the first deploy and whenever it has changed since.
if [[ "$(cat /var/lib/buildquantify/setup-done 2>/dev/null)" \
      != "$(sha256sum deploy/setup-ubuntu.sh | cut -d' ' -f1)" || ! -f .env ]]; then
  echo "== Preparing the server (setup-ubuntu.sh is new here or changed)"
  if ! sudo -n true 2>/dev/null; then
    echo "sudo asks for a password here. On the server, run once:" >&2
    echo "  cd $dir && sudo ./deploy/setup-ubuntu.sh" >&2
    exit 1
  fi
  sudo ./deploy/setup-ubuntu.sh
fi
