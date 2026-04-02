#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
  set +e
else
  set -e
fi
{
  # Get the Git branch
  parse_git_branch() {
    git branch 2>/dev/null | sed -e "/^[^*]/d" -e "s/* \(.*\)/ (\1)/"
  }

  # Make Git branch a variable
  branch="$(git branch | sed -n -e "s/^\* \(.*\)/\1/p")"

  # Git commands
  alias log="git log"
  alias wut='git log master...${branch} --oneline'
  alias diff="git diff"
  alias branch="git branch"
  alias status="git status"
  alias st="git status"
  alias fetch="git fetch"
  alias push="git push origin head"
  alias pull="git pull"
  alias fp="fetch && pull"
  alias gmm="git merge master"
  alias recent="git for-each-ref --sort=-committerdate refs/heads/"
  alias branch_new="git for-each-ref --sort=-committerdate refs/heads/ --format=%(refname:short)"
  alias add="git add -A"
  alias gac="git add -A && git commit"
  alias gsur="git submodule update --remote"
  alias glf="git ls-files"
  alias gl="git log --graph --pretty=oneline --abbrev-commit --decorate"

  ## Git branch switching
  alias master="git co master"
  alias ghp="git co gh-pages"

  # Others
  alias editgit="nano ~/.gitconfig"
} >>"${HOME}"/./bashrc
