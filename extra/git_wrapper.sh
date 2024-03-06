#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail

# Declare constants.
readonly ansi_clear='\033[0m'
readonly ansi_green='\033[1;32m'
readonly ansi_grey='\033[1;90m'
readonly ansi_magenta='\033[1;35m'
readonly ansi_red='\033[1;31m'
readonly git_branch_format="\
%(if)%(HEAD)%(then)%(color:green)\
%(else)\
%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:red)\
%(else)\
%(color:white)\
%(end)\
%(end)\
%(align:width=40)%(refname:short)%(HEAD)%(end)\
%(color:dim white)Last commit %(color:reset)\
%(color:yellow)%(objectname:short)%(color:reset) \
%(color:dim white)by%(color:reset) \
%(color:magenta)%(authorname) \
%(color:cyan)%(committerdate:relative) \
%(if)%(upstream)%(then)\
%(if:equals==)%(upstream:trackshort)%(then)%(color:green)(synced)\
%(else)\
%(if:equals=<)%(upstream:trackshort)%(then)%(color:yellow)\
%(else)\
%(color:red)\
%(end)\
(%(upstream:track,nobracket))\
%(end)\
%(end)"

###############################################################################
#
#  Add files.
#
#  One or more file names can be given.
#
#  If no file names are given, pick them with a selector.
#
#  Arguments:
#    Strings (optional). The names of the files to be added.
#
###############################################################################
git_add() {
  # Get the files to add.
  if [[ -n ${1-} ]]; then
    files="$*"
  else
    set +o errexit
    files=$(
      git -c color.ui=always status --short \
        | fzf --ansi --header='Select files to stage' --multi --no-info \
        | awk '{ print $2 }'
    )
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No files selected'
  fi

  # Add the files.
  initial_diff_hash=$(_staged_diff_hash)
  echo "${files}" | xargs git add
  final_diff_hash=$(_staged_diff_hash)

  # Show information.
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  _print_changes
  _print_latest_commit
}

###############################################################################
#
#  Add all changed files.
#
#  Arguments:
#    None.
#
###############################################################################
git_add_all() {
  # Add the files.
  initial_diff_hash=$(_staged_diff_hash)
  git add --all
  final_diff_hash=$(_staged_diff_hash)

  # Show information.
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  _print_changes
  _print_latest_commit
}

###############################################################################
#
#  Add all changed files then show a diff of staged changes.
#
#  Arguments:
#    None.
#
###############################################################################
git_add_all_then_diff() {
  # Add the files.
  initial_diff_hash=$(_staged_diff_hash)
  git add --all
  final_diff_hash=$(_staged_diff_hash)

  # Show information.
  if [[ "${initial_diff_hash}" != "${final_diff_hash}" ]]; then
    git diff --staged
  fi
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  _print_changes
  _print_latest_commit
}

###############################################################################
#
#  Add files with the --patch option.
#
#  One or more file names can be given.
#
#  If no file names are given, all changed files are selected.
#
#  Arguments:
#    Strings (optional). The names of the files to be added.
#
###############################################################################
git_add_with_patch() {
  # Add the files.
  initial_diff_hash=$(_staged_diff_hash)
  git add --patch "${@}"
  final_diff_hash=$(_staged_diff_hash)

  # Show information.
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  _print_changes
  _print_latest_commit
}

###############################################################################
#
#  Do a branch operation.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the branch operation.
#
###############################################################################
git_branch() {
  git branch "${@}"
}

###############################################################################
#
#  Create a branch then switch to it.
#
#  Arguments:
#    String. The name for the new branch.
#
###############################################################################
git_branch_create() {
  # Check that a branch name is given.
  if [[ -z ${1-} ]]; then
    _print_failure_message 'A new branch name is required'
    exit 1
  fi

  # Create the new branch and switch to it.
  git branch "${@}"
  git switch --quiet "${1}"

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_latest_commit
  _print_branches local 5
}

###############################################################################
#
#  Delete branches.
#
#  Branches can be local or remote.
#
#  One or more branch names can be given.
#
#  If no branch names are given, pick them with a selector.
#
#  Arguments:
#    Strings (optional). The branches to be deleted.
#
###############################################################################
git_branch_delete() {
  # Get the branches to delete.
  if [[ -n ${1-} ]]; then
    branches=$(printf '%s\n' "$@")
  else
    current_branch=$(_current_branch)
    fzf_header='Select the branches to delete'
    set +o errexit
    branches=$(
      _branches all \
        | grep --invert-match "\[32m${current_branch}\*" \
        | fzf --ansi --header="${fzf_header}" --multi --no-info --nth 1
    )
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No branches selected'
  fi

  # Confirm that the branches should be deleted.
  echo
  _print_magenta 'Branches to be deleted'
  echo "${branches}"
  echo
  read -p 'Delete? (y/n): ' -r response
  while [[ ${response} != 'y' && ${response} != 'n' ]]; do
    read -p "Please enter either 'y' or 'n': " -r response
  done
  if [[ "${response}" != "y" ]]; then
    exit 1
  fi

  # Delete the branches.
  overall_exit_code=0
  echo
  branch_names=$(echo "${branches}" | awk '{ print $1 }')
  for branch in ${branch_names}; do
    set +o errexit
    if [[ "${branch}" =~ '/' ]]; then
      git push --delete --quiet "${branch%/*}" "${branch#*/}"
    else
      git branch --delete --force --quiet "${branch}" &>/dev/null
    fi
    exit_code=$?
    set -o errexit
    if [[ ${exit_code} == 0 ]]; then
      _print_success_message "Branch '${branch}' was deleted"
    else
      _print_failure_message "Branch '${branch}' was not deleted"
      overall_exit_code=${exit_code}
    fi
  done

  # Show information.
  _print_branches all 10

  # Exit with a non-zero code if any branches could not be deleted.
  exit ${overall_exit_code}
}

###############################################################################
#
#  Show local and remote branches.
#
#  Arguments:
#    String (optional). A pattern to filter the list of branches with.
#
###############################################################################
git_branch_list_all() {
  # Get the branches.
  branches=$(_branches all)

  # Show the branches.
  if [[ -n ${1-} ]]; then
    echo "${branches}" | awk -v pattern="${1}" '$1 ~ pattern'
  else
    echo "${branches}"
  fi
}

###############################################################################
#
#  Show local branches.
#
#  Arguments:
#    String (optional). A pattern to filter the list of branches with.
#
###############################################################################
git_branch_list_local() {
  # Get the branches.
  branches=$(_branches local)

  # Show the branches.
  if [[ -n ${1-} ]]; then
    echo "${branches}" | awk -v pattern="${1}" '$1 ~ pattern'
  else
    echo "${branches}"
  fi
}

###############################################################################
#
#  Show remote branches.
#
#  Arguments:
#    String (optional). A pattern to filter the list of branches with.
#
###############################################################################
git_branch_list_remote() {
  # Get the branches.
  branches=$(_branches remote)

  # Show the branches.
  if [[ -n ${1-} ]]; then
    echo "${branches}" | awk -v pattern="${1}" '$1 ~ pattern'
  else
    echo "${branches}"
  fi
}

###############################################################################
#
#  Rename a branch.
#
#  Arguments:
#    String. The new branch name.
#
###############################################################################
git_branch_rename() {
  # Check that a new branch name is given.
  if [[ -z ${1-} ]]; then
    _print_failure_message 'A new branch name is required'
    exit 1
  fi

  # Rename the branch.
  old_branch_name=$(_current_branch)
  git branch --move "${1}"
  new_branch_name=$(_current_branch)

  # Show information.
  _print_result "${old_branch_name}" "${new_branch_name}"
  _print_branches local 5
}

###############################################################################
#
#  Set the upstream of the current branch to the matching remote branch.
#
#  Arguments:
#    None.
#
###############################################################################
git_branch_set_upstream() {
  # Set the upstream branch.
  remote=$(git remote)
  branch=$(_current_branch)
  git branch --set-upstream-to="${remote}/${branch}" "${branch}"

  # Show information.
  _print_success_message 'Done'
}

###############################################################################
#
#  Check out a branch or commit.
#
#  Arguments:
#    Strings. The parameters to pass to the checkout operation.
#
###############################################################################
git_checkout() {
  # Do the checkout.
  initial_branch=$(_current_branch)
  git checkout --quiet "${@}"
  final_branch=$(_current_branch)

  # Show information.
  _print_result "${initial_branch}" "${final_branch}"
  if [[ "${initial_branch}" != "${final_branch}" ]]; then
    _print_changes
    _print_recent_commits
  fi
}

###############################################################################
#
#  Cherry-pick a commit.
#
#  If no branch or commit is given, pick them with a selector.
#
#  Arguments:
#    String (optional). Branch or commit.
#
###############################################################################
git_cherry_pick() {
  # Do the cherry-pick.
  initial_commit_hash=$(_latest_commit_hash)
  if [[ -n ${1-} ]]; then
    git cherry-pick "${1}"
  else
    set +o errexit
    branch=$(
      _select_any_other_branch 'Select the branch to cherry-pick from'
    )
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No branch selected'

    set +o errexit
    commit=$(_select_commit 'Select the commit to cherry-pick' "${branch}")
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No commit selected'

    git cherry-pick "${commit}"
  fi
  final_commit_hash=$(_latest_commit_hash)

  # Show information.
  _print_result "${initial_commit_hash}" "${final_commit_hash}"
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Abort a cherry-pick.
#
#  Arguments:
#    None.
#
###############################################################################
git_cherry_pick_abort() {
  # Abort the cherry-pick.
  git cherry-pick --abort

  # Show information.
  _print_success_message 'Cherry-pick aborted'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Continue a cherry-pick.
#
#  Arguments:
#    None.
#
###############################################################################
git_cherry_pick_continue() {
  git cherry-pick --continue
}

###############################################################################
#
#  Clean untracked files.
#
#  Arguments:
#    None.
#
###############################################################################
git_clean() {
  # Do the clean.
  initial_untracked_files=$(_untracked_files)
  git clean -d --force --quiet
  final_untracked_files=$(_untracked_files)

  # Show information.
  _print_result "${initial_untracked_files}" "${final_untracked_files}"
  _print_changes
}

###############################################################################
#
#  Commit staged changes.
#
#  Arguments:
#    String (optional). Commit message.
#
###############################################################################
git_commit() {
  # Make the commit.
  if [[ -n ${1-} ]]; then
    git commit --message="${*}" --quiet
  else
    git commit --quiet
  fi

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Amend a commit and optionally change the commit message.
#
#  Arguments:
#    None.
#
###############################################################################
git_commit_amend() {
  # Amend the commit.
  git commit --amend --quiet

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Amend a commit without changing the commit message.
#
#  Arguments:
#    None.
#
###############################################################################
git_commit_amend_reuse_message() {
  # Amend the commit.
  git commit --amend --quiet --reuse-message=HEAD

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Commit staged changes with the message "Checkpoint"
#
#  Arguments:
#    None.
#
###############################################################################
git_commit_checkpoint() {
  git_commit 'Checkpoint'
}

###############################################################################
#
#  Commit staged changes with the --fixup option.
#
#  Arguments:
#    None
#
###############################################################################
git_commit_fixup() {
  # Don't run the commit selector if there is nothing to commit.
  if [[ -z $(git diff --staged) ]]; then
    _print_failure_message 'Nothing staged to commit'
    exit 1
  fi

  # Get the commit to fixup.
  set +o errexit
  commit=$(_select_commit 'Select the commit to fixup')
  exit_code=$?
  set -o errexit
  _exit_on_error ${exit_code} 'No commit selected'

  # Make the commit.
  git commit --fixup="${commit}" --quiet

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Do a diff operation.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the diff operation.
#
###############################################################################
git_diff() {
  git diff "${@}"
}

###############################################################################
#
#  Diff the current local branch with the remote branch of the same name.
#
#  Arguments:
#    None.
#
###############################################################################
git_diff_remote() {
  # Get remote and branch names.
  remote=$(git remote)
  branch=$(_current_branch)
  remote_branch="${remote}/${branch}"

  # Don't do the diff if there is no remote branch to diff with.
  if ! git branch --list --remote | grep --quiet "${remote_branch}"; then
    _print_failure_message "There is no ${remote_branch} branch"
    exit 1
  fi

  # Do the diff.
  if [[ -n $(git diff "${remote_branch}" "${branch}") ]]; then
    git diff "${remote_branch}" "${branch}"
  else
    _print_success_message 'No difference'
  fi
}

###############################################################################
#
#  Diff the staged files.
#
#  Arguments:
#    None.
#
###############################################################################
git_diff_staged() {
  git diff --staged
}

###############################################################################
#
#  Diff the unstaged files.
#
#  Arguments:
#    None.
#
###############################################################################
git_diff_unstaged() {
  git diff
}

###############################################################################
#
#  Fetch all remotes with the --prune option.
#
#  Arguments:
#    None.
#
###############################################################################
git_fetch() {
  # Do the fetch.
  git fetch --all --prune

  # Show information.
  _print_success_message 'Done'
  _print_branches remote 10
}

###############################################################################
#
#  Show the most recent commit history.
#
#  Arguments:
#    Int (optional). The number of commits to show.
#
###############################################################################
git_log() {
  # Show the commits.
  if [[ -n ${1-} ]]; then
    git log --max-count="${1}"
  else
    git log --max-count=10
  fi
}

###############################################################################
#
#  Show the complete commit history as a graph.
#
#  Arguments:
#    None.
#
###############################################################################
git_log_graph() {
  git log --all --graph
}

###############################################################################
#
#  Merge a branch or commit.
#
#  If no branch or commit is given, pick them with a selector.
#
#  Arguments:
#    String (optional). Branch or commit.
#
###############################################################################
git_merge() {
  # Do the merge.
  initial_commit_hash=$(_latest_commit_hash)
  if [[ -n ${1-} ]]; then
    git merge --quiet "${@}"
  else
    set +o errexit
    branch=$(
      _select_any_other_branch \
        'Select the branch containing the commit to merge'
    )
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No branch selected'

    set +o errexit
    commit=$(_select_commit 'Select the commit to merge' "${branch}")
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No commit selected'
    git merge --quiet "${commit}"
  fi
  final_commit_hash=$(_latest_commit_hash)

  # Show information.
  _print_result "${initial_commit_hash}" "${final_commit_hash}"
  if [[ "${initial_commit_hash}" != "${final_commit_hash}" ]]; then
    _print_changes
    _print_recent_commits
  fi
}

###############################################################################
#
#  Pull changes from the remote.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the pull operation.
#
###############################################################################
git_pull() {
  # Do the pull.
  initial_commit_hash=$(_latest_commit_hash)
  initial_commit_count=$(_commit_count)
  git pull --quiet "${@}"
  final_commit_hash=$(_latest_commit_hash)
  final_commit_count=$(_commit_count)

  # Show information.
  _print_result "${initial_commit_hash}" "${final_commit_hash}"
  if [[ "${initial_commit_hash}" != "${final_commit_hash}" ]]; then
    echo
    _print_magenta 'Commits pulled'
    commits_pulled_count=$((final_commit_count - initial_commit_count))
    git log --max-count="${commits_pulled_count}"
  else
    _print_success_message 'No changes to pull'
  fi
}

###############################################################################
#
#  Push changes to the remote.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the push operation.
#
###############################################################################
git_push() {
  # Get remote and branch names.
  remote=$(git remote)
  branch=$(_current_branch)
  remote_branch="${remote}/${branch}"

  # If there is no remote branch yet, do the push, show information, then
  # exit.
  if ! git branch --list --remote | grep --quiet "${remote_branch}"; then
    git push --quiet "${@}"
    _print_success_message 'Done'
    _print_success_message "New branch ${remote_branch} created"
    exit 0
  fi

  # If there is a remote branch, do the push.
  initial_remote_commit_hash=$(_latest_commit_hash "${remote_branch}")
  initial_remote_commit_count=$(_commit_count "${remote_branch}")
  git push --quiet "${@}"
  final_remote_commit_hash=$(_latest_commit_hash "${remote_branch}")
  final_remote_commit_count=$(_commit_count "${remote_branch}")

  # Show information.
  _print_result "${initial_remote_commit_hash}" "${final_remote_commit_hash}"
  if [[ 
    ${initial_remote_commit_hash} != "${final_remote_commit_hash}" ]] \
    ; then
    echo
    _print_magenta 'Commits pushed'
    remote_commits_pushed_count=$((\
      final_remote_commit_count - initial_remote_commit_count))
    git log --max-count="${remote_commits_pushed_count}"
  fi
}

###############################################################################
#
#  Push changes to the remote with the --force-with-lease option.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the push operation.
#
###############################################################################
git_push_force_with_lease() {
  # Do the push.
  git push --force-with-lease --quiet "${@}"

  # Show information.
  _print_success_message 'Done'
  _print_changes
}

###############################################################################
#
#  Rebase the current branch onto another branch.
#
#  Arguments:
#    String (optional). The branch to rebase onto.
#
###############################################################################
git_rebase() {
  # Get the branch to rebase onto.
  if [[ -n ${1-} ]]; then
    target_branch="${1}"
  else
    set +o errexit
    target_branch=$(
      _select_any_other_branch 'Select the branch to rebase onto'
    )
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No branch selected'
  fi

  # Do the rebase.
  initial_rebasing_branch_commit_hash=$(_latest_commit_hash)
  initial_target_branch_commit_count=$(_commit_count "${target_branch}")
  git rebase --quiet "${target_branch}"
  final_rebasing_branch_commit_hash=$(_latest_commit_hash)
  final_rebasing_branch_commit_count=$(_commit_count)

  # Show information.
  _print_result \
    "${initial_rebasing_branch_commit_hash}" \
    "${final_rebasing_branch_commit_hash}"
  if [[ 
    "${initial_rebasing_branch_commit_hash}" != "${final_rebasing_branch_commit_hash}" ]] \
    ; then
    _print_success_message "Rebased onto ${target_branch}"
    echo
    _print_magenta 'Commits rebased'
    commits_rebased_count=$((\
      final_rebasing_branch_commit_count - \
      initial_target_branch_commit_count))
    git log --max-count="${commits_rebased_count}"
  fi
}

###############################################################################
#
#  Abort a rebase.
#
#  Arguments:
#    None.
#
###############################################################################
git_rebase_abort() {
  # Abort the rebase.
  git rebase --abort

  # Show information.
  _print_success_message 'Rebase aborted'
  _print_latest_commit
  _print_changes
}

###############################################################################
#
#  Continue a rebase.
#
#  Arguments:
#    None.
#
###############################################################################
git_rebase_continue() {
  git rebase --continue
}

###############################################################################
#
#  Rebase the current branch with the --interactive option.
#
#  Arguments:
#    None.
#
###############################################################################
git_rebase_interactive() {
  # Unstaged changes will cause the rebase to fail, so exit if there are any.
  if [[ -n $(git diff) ]]; then
    _print_failure_message 'There are unstaged changes'
    exit 1
  fi

  # Get the commit to rebase from.
  set +o errexit
  selected_commit=$(_select_commit 'Select the commit to rebase from')
  exit_code=$?
  set -o errexit
  _exit_on_error ${exit_code} 'No commit selected'
  # Use git log rather than a plumbing command because it's the only way to
  # handle a root commit being selected without crashing.
  parent_commit=$(git log --pretty=%P -n 1 "${selected_commit}")
  if [[ -n ${parent_commit} ]]; then
    target_commit="${parent_commit}"
  else
    target_commit="${selected_commit}"
  fi

  # Do the rebase.
  initial_commit_hash=$(_latest_commit_hash)
  commits_before_target_commit_count=$(_commit_count "${target_commit}")
  if [[ -n ${parent_commit} ]]; then
    git rebase --interactive --quiet "${target_commit}"
  else
    git rebase --interactive --quiet --root "${target_commit}"
  fi
  final_commit_hash=$(_latest_commit_hash)
  current_branch_commit_count=$(_commit_count)
  rebased_commits_count=$((\
    current_branch_commit_count - \
    commits_before_target_commit_count))

  # Show information.
  _print_result "${initial_commit_hash}" "${final_commit_hash}"
  if [[ "${initial_commit_hash}" != "${final_commit_hash}" ]]; then
    echo
    _print_magenta 'Rebased commits'
    git log --max-count="${rebased_commits_count}"
  fi
}

###############################################################################
#
#  Rebase the current branch with the --autosquash and --interactive options.
#
#  Arguments:
#    None.
#
###############################################################################
git_rebase_interactive_with_autosquash() {
  # Unstaged changes will cause the rebase to fail, so exit if there are any.
  if [[ -n $(git diff) ]]; then
    _print_failure_message 'There are unstaged changes'
    exit 1
  fi

  # Get the commit to rebase from.
  set +o errexit
  selected_commit=$(_select_commit 'Select the commit to rebase from')
  exit_code=$?
  set -o errexit
  _exit_on_error ${exit_code} 'No commit selected'
  # Use git log rather than a plumbing command because it's the only way to
  # handle a root commit being selected without crashing.
  parent_commit=$(git log --pretty=%P -n 1 "${selected_commit}")
  if [[ -n ${parent_commit} ]]; then
    target_commit="${parent_commit}"
  else
    target_commit="${selected_commit}"
  fi

  # Do the rebase.
  initial_commit_hash=$(_latest_commit_hash)
  commits_before_target_commit_count=$(_commit_count "${target_commit}")
  if [[ -n ${parent_commit} ]]; then
    git rebase --autosquash --interactive --quiet "${target_commit}"
  else
    git rebase --autosquash --interactive --quiet --root "${target_commit}"
  fi
  final_commit_hash=$(_latest_commit_hash)
  current_branch_commit_count=$(_commit_count)
  rebased_commits_count=$((\
    current_branch_commit_count - \
    commits_before_target_commit_count))

  # Show information.
  _print_result "${initial_commit_hash}" "${final_commit_hash}"
  if [[ "${initial_commit_hash}" != "${final_commit_hash}" ]]; then
    echo
    _print_magenta 'Rebased commits'
    git log --max-count="${rebased_commits_count}"
  fi
}

###############################################################################
#
#  Undo commits.
#
#  Arguments:
#    Int. The number of commits to undo.
#
###############################################################################
git_reset_head() {
  # Check that the number of commits is given.
  if [[ -z ${1-} ]]; then
    _print_failure_message 'The number of commits to undo is required.'
    exit 1
  fi

  # Undo the commits.
  git reset --quiet HEAD~"${1}"

  # Show information.
  _print_success_message 'Done'
  _print_changes
  _print_recent_commits
}

###############################################################################
#
#  Show the latest commit on the current branch.
#
#  Arguments:
#    None.
#
###############################################################################
git_show() {
  git show --format=full
}

###############################################################################
#
#  Stash changes.
#
#  Arguments:
#    None.
#
###############################################################################
git_stash() {
  # Stash the changes.
  initial_staged_diff=$(_staged_diff_hash)
  initial_unstaged_diff=$(_unstaged_diff_hash)
  git stash --quiet
  final_staged_diff=$(_staged_diff_hash)
  final_unstaged_diff=$(_unstaged_diff_hash)

  # Show information.
  _print_result \
    "${initial_staged_diff}${initial_unstaged_diff}" \
    "${final_staged_diff}${final_unstaged_diff}"
  if [[ 
    "${initial_staged_diff}${initial_unstaged_diff}" != "${final_staged_diff}${final_unstaged_diff}" ]] \
    ; then
    _print_changes
    _print_latest_commit
  fi
}

###############################################################################
#
#  Pop stashed changes.
#
#  Arguments:
#    None.
#
###############################################################################
git_stash_pop() {
  # Pop the stashed changes.
  initial_staged_diff=$(_staged_diff_hash)
  initial_unstaged_diff=$(_unstaged_diff_hash)
  git stash pop --quiet
  final_staged_diff=$(_staged_diff_hash)
  final_unstaged_diff=$(_unstaged_diff_hash)

  # Show information.
  _print_result \
    "${initial_staged_diff}${initial_unstaged_diff}" \
    "${final_staged_diff}${final_unstaged_diff}"
  if [[ 
    "${initial_staged_diff}${initial_unstaged_diff}" != "${final_staged_diff}${final_unstaged_diff}" ]] \
    ; then
    _print_changes
    _print_latest_commit
  fi
}

###############################################################################
#
#  Show status.
#
#  Arguments:
#    None.
#
###############################################################################
git_status() {
  # Check that the command was issued inside a repository.
  if ! git rev-parse --show-toplevel &>/dev/null; then
    _print_failure_message 'Not in a repository'
    exit 1
  fi

  # Show information.
  _print_changes
  _print_latest_commit
}

###############################################################################
#
#  Switch to a different branch.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the switch operation.
#
###############################################################################
git_switch() {
  # Switch to a different branch.
  initial_branch=$(_current_branch)
  if [[ -n ${1-} ]]; then
    git switch --quiet "${@}"
  else
    set +o errexit
    branch=$(_select_branch_to_switch_to)
    exit_code=$?
    set -o errexit
    _exit_on_error ${exit_code} 'No branch selected'
    git switch --quiet "${branch}"
  fi
  final_branch=$(_current_branch)

  # Show information.
  _print_result "${initial_branch}" "${final_branch}"
  if [[ "${initial_branch}" != "${final_branch}" ]]; then
    _print_changes
    _print_recent_commits
  fi
}

###############################################################################
#
#  Undo unstaged changes.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the restore operation.
#
###############################################################################
git_unchange() {
  # Undo the unstaged changes.
  initial_diff_hash=$(_unstaged_diff_hash)
  if [[ -n ${1-} ]]; then
    git restore "${@}"
  else
    git restore .
  fi
  final_diff_hash=$(_unstaged_diff_hash)

  # Show information.
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  if [[ "${initial_diff_hash}" != "${final_diff_hash}" ]]; then
    _print_changes
    _print_recent_commits
  fi
}

###############################################################################
#
#  Unstage staged changes.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the restore operation.
#
###############################################################################
git_unstage() {
  # Unstage the staged changes.
  initial_diff_hash=$(_staged_diff_hash)
  if [[ -n ${1-} ]]; then
    git restore --staged "${@}"
  else
    git restore --staged .
  fi
  final_diff_hash=$(_staged_diff_hash)

  # Show information.
  _print_result "${initial_diff_hash}" "${final_diff_hash}"
  if [[ "${initial_diff_hash}" != "${final_diff_hash}" ]]; then
    _print_changes
  fi
}

# Private functions.

###############################################################################
#
#  Get a list of branches.
#
#  Arguments:
#    String. The type of branch. Options are "all", "local" and "remotes".
#
###############################################################################
_branches() {
  # The --color=always switch is required to retain colours when this
  # function is piped to fzf.
  if [[ ${1} != 'local' ]]; then
    option="--${1}"
    git branch --color=always --format="${git_branch_format}" "${option}"
  else
    git branch --color=always --format="${git_branch_format}"
  fi

}

###############################################################################
#
#  Count the commits eiher on a branch or up to a commit.
#
#  Arguments:
#    String (optional). The branch to count on, or the commit to count up to.
#
###############################################################################
_commit_count() {
  if [[ -n ${1-} ]]; then
    git log "${1-}" | wc --lines
  else
    git log | wc --lines
  fi
}

###############################################################################
#
#  Get the name of the current branch.
#
#  Arguments:
#    None.
#
###############################################################################
_current_branch() {
  git branch --show-current
}

###############################################################################
#
#  Exit if the exit code is non-zero.
#
#  Arguments:
#    Int. The last operation's exit code.
#    String. The message to exit with.
#
###############################################################################
_exit_on_error() {
  if [[ ${1} != 0 ]]; then
    _print_failure_message "${2}"
    exit 1
  fi
}

###############################################################################
#
#  Get the hash of the most recent commit on a branch.
#
#  The branch is the current branch, unless a branch name is given.
#
#  Arguments:
#    String (optional). The branch to get the current commit from.
#
###############################################################################
_latest_commit_hash() {
  if [[ -n ${1-} ]]; then
    git show --no-patch --format=%h "${1}"
  else
    git show --no-patch --format=%h
  fi
}

###############################################################################
#
#  Show branches.
#
#  Arguments:
#    String. The type of branch. Options are "all", "local" and "remotes".
#    Int. The number of branches to show.
#
###############################################################################
_print_branches() {
  branches=$(_branches "${1}")

  echo
  case ${1} in
    all)
      _print_magenta 'All branches'
      ;;
    remote)
      _print_magenta 'Remote branches'
      ;;
    local)
      _print_magenta 'Local branches'
      ;;
    *)
      echo 'Either "all", "local" or "remote" must be specified'
      exit 1
      ;;
  esac

  branch_count=$(echo "${branches}" | wc --lines)
  no_of_branches_to_show="${2}"
  if [[ ${branch_count} -le ${no_of_branches_to_show} ]]; then
    echo "${branches}"
  else
    echo "${branches}" | head --lines="${no_of_branches_to_show}"
    trimmed_branch_count=$((branch_count - no_of_branches_to_show))
    _print_grey "+ ${trimmed_branch_count} more branches"
  fi
}

###############################################################################
#
#  Show a message with the result of an operation.
#
#  Arguments:
#    String. A representation of the state before the operation.
#    String. A representation of the state after the operation.
#
###############################################################################
_print_result() {
  if [[ ${1} != "${2}" ]]; then
    _print_success_message 'Done'
  else
    _print_failure_message 'Nothing done'
  fi
}

###############################################################################
#
#  Show staged and unstaged changes.
#
#  Arguments:
#    None.
#
###############################################################################
_print_changes() {
  echo
  _print_magenta 'Changes'
  changes=$(git -c color.ui=always status --short)
  if [[ -n ${changes} ]]; then
    echo "${changes}"
  else
    echo '-'
  fi
}

###############################################################################
#
#  Print a failute message in red.
#
#  Arguments:
#    String. The message.
#
###############################################################################
_print_failure_message() {
  echo -e "${ansi_red}✗ ${1}${ansi_clear}"
}

###############################################################################
#
#  Print a string in grey.
#
#  Arguments:
#    String. The string to print.
#
###############################################################################
_print_grey() {
  echo -e "${ansi_grey}${1}${ansi_clear}"
}

###############################################################################
#
#  Show a the latest commit on the current branch.
#
#  Arguments:
#    None.
#
###############################################################################
_print_latest_commit() {
  echo
  _print_magenta 'Latest commit'
  format='%C(auto)%h%C(dim white)%C(auto)%Creset %s %C(dim white)by %an %ar'
  git show --format="${format}" --no-patch
}

###############################################################################
#
#  Print a string in magenta.
#
#  Arguments:
#    String. The string to print.
#
###############################################################################
_print_magenta() {
  echo -e "${ansi_magenta}${1}${ansi_clear}"
}

###############################################################################
#
#  Show the five most recent commits.
#
#  Arguments:
#    None
#
###############################################################################
_print_recent_commits() {
  echo
  _print_magenta 'Latest commits'
  commits=$(git log --color=always --max-count=5)
  if [[ -n ${commits} ]]; then
    echo "${commits}"
  else
    echo '-'
  fi
}

###############################################################################
#
#  Print a success message in green.
#
#  Arguments:
#    String. The message.
#
###############################################################################
_print_success_message() {
  echo -e "${ansi_green}🗸 ${1}${ansi_clear}"
}

###############################################################################
#
#  Select any local or remote branch except for the current local branch.
#
#  Arguments:
#    String. The header for the fzf selector.
#
###############################################################################
_select_any_other_branch() {
  current_branch=$(_current_branch)

  _branches all \
    | grep --invert-match "\[32m${current_branch}\*" \
    | fzf --ansi --header="${1}" --no-info --nth 1 \
    | awk '{ print $1 }'
}

###############################################################################
#
#  Select a branch to switch to.
#
#  This means any local branch except for the current branch, or any remote
#  branch without a matching local branch.
#
#  Arguments:
#    None.
#
###############################################################################
_select_branch_to_switch_to() {
  remote=$(git remote)
  current_branch=$(_current_branch)

  remote_branches_to_exclude=$(git branch | xargs printf "${remote}/%s\n")
  fzf_header="Select the branch to switch to from '${current_branch}'"

  git branch --all --color=always --format="${git_branch_format}" \
    | grep --fixed-strings --invert-match "${remote_branches_to_exclude}" \
    | grep --invert-match "\[31m${remote}/HEAD\s" \
    | grep --invert-match "\[32m${current_branch}\*" \
    | fzf --ansi --header="${fzf_header}" --no-info --nth 1 \
    | awk '{ print $1 }' \
    | sed "s/^${remote}\///"
}

###############################################################################
#
#  Select a commit.
#
#  Arguments:
#    String. The header for the fzf selector.
#    String (optional). The branch to select the commit from.
#
###############################################################################
_select_commit() {
  if [[ -n ${2-} ]]; then
    commits=$(git log --color=always "${2}")
  else
    commits=$(git log --color=always)
  fi

  echo "${commits}" \
    | fzf --ansi --header="${1}" --no-info \
    | awk '{ print $1 }'
}

###############################################################################
#
#  Get the hash of the diff of the staged changes.
#
#  Arguments:
#    None.
#
###############################################################################
_staged_diff_hash() {
  git diff --staged | sha512sum
}

###############################################################################
#
#  Get the hash of the diff of the unstaged changes.
#
#  Arguments:
#    None.
#
###############################################################################
_unstaged_diff_hash() {
  git diff | sha512sum
}

###############################################################################
#
#  Get the names of the untracked files.
#
#  Arguments:
#    None.
#
###############################################################################
_untracked_files() {
  git ls-files --exclude-standard --other
}

# Run the command.
# shellcheck disable=2086
git_${*}
