#!/bin/bash

# Set intuitive error behaviour.
set -o errexit -o nounset -o pipefail


# Declare constants.
readonly ANSI_CLEAR='\033[0m'
readonly ANSI_GREEN='\033[1;32m'
readonly ANSI_GREY='\033[1;90m'
readonly ANSI_MAGENTA='\033[1;35m'
readonly ANSI_RED='\033[1;31m'  # TODO: Or 91m?
readonly ANSI_YELLOW='\033[1;33m'
readonly GIT_BRANCH_FORMAT="\
%(if)%(HEAD)%(then)%(color:bold green)\
%(else)\
%(if:equals=refs/remotes)%(refname:rstrip=-2)%(then)%(color:bold red)\
%(else)\
%(color:bold yellow)\
%(end)\
%(end)\
%(align:width=35)%(refname:short)%(HEAD)%(color:reset)%(end)\
%(color:dim white)Last commit %(color:reset)\
%(color:bold white)%(objectname:short) %(color:reset)\
%(color:bold cyan)%(committerdate:relative) %(color:reset)\
%(color:dim white)by %(color:reset)\
%(color:bold magenta)%(authorname) %(color:reset)\
%(if)%(upstream)%(then)\
%(if:equals==)%(upstream:trackshort)%(then)%(color:bold green)(synced)\
%(else)\
%(if:equals=<)%(upstream:trackshort)%(then)%(color:bold yellow)\
%(else)\
%(color:bold red)\
%(end)\
(%(upstream:track,nobracket))\
%(end)\
%(end)"


# TODO: Handle all instances of fzf returning nothing as errors to raise a
# message about.


###############################################################################
#
#  Add files.
#
#  One or more file names can be given.
#
#  If no file names are given, fzf is used to select files.
#
#  Arguments:
#    Strings (optional). The file names to be added.
#
###############################################################################
git_add() {
    # Get the files to add.
    if [[ ${1-} ]]; then
        files=$(printf '%s\n' "$@")
    else
        files=$(_get_files_to_add_with_fzf)
    fi

    # Add the files.
    initial_diff=$(_staged_diff_hash)
    git add "${files}"
    final_diff=$(_staged_diff_hash)

    # Show information.
    _show_changed_message "${initial_diff}" "${final_diff}"
    _changes
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
    initial_diff=$(_staged_diff_hash)
    git add --all
    final_diff=$(_staged_diff_hash)

    # Show information.
    _show_changed_message "${initial_diff}" "${final_diff}"
    _changes
}


###############################################################################
#
#  Add files then show a diff of staged changes.
#
#  One or more file names can be given.
#
#  If no file names are given, fzf is used to select files.
#
#  Arguments:
#    Strings (optional). The file names to be added.
#
###############################################################################
git_add_then_git_diff() {
    # Get the files to add.
    if [[ ${1-} ]]; then
        files=$(printf '%s\n' "$@")
    else
        files=$(_get_files_to_add_with_fzf)
    fi

    # Add the files.
    initial_diff=$(_staged_diff_hash)
    git add "${files}"
    final_diff=$(_staged_diff_hash)

    # Show information.
    if [[ ${initial_diff} != "${final_diff}" ]]; then
        git_diff_staged
    fi
    _show_changed_message "${initial_diff}" "${final_diff}"
    _changes
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
#    Strings (optional). The file names to be added.
#
###############################################################################
git_add_with_patch() {
    # Add the files.
    initial_diff=$(_staged_diff_hash)
    git add --patch "${@}"
    final_diff=$(_staged_diff_hash)

    # Show information.
    _show_changed_message "${initial_diff}" "${final_diff}"
    _changes
}


###############################################################################
#
#  Do a branch operation.
#
#  Arguments:
#    Strings (optional). The parameters to pass to the Git branch operation.
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
#    Strings. The branch and (optionally) the commit to branch from.
#
###############################################################################
git_branch_create() {
    # Check that a branch name is given.
    if [[ -z ${1-} ]]; then
        _warning 'A new branch name is required.'
        return 1
    fi

    # Create the new branch and switch to it.
    git branch "${@}"
    git switch --quiet "${1}"

    # Show information.
    _success 'Done'
    _changes
    _local_branches
}


###############################################################################
#
#  Delete branches.
#
#  Branches can be local or remote.
#
#  One or more branch names can be given.
#
#  If no branch names are given, fzf is used to select branches.
#
#  Arguments:
#    Strings (optional). The branches to be deleted.
#
###############################################################################
git_branches_delete() {
    # Get the branches to delete.
    if [[ ${1-} ]]; then
        branches=$(printf '%s\n' "$@")
    else
        current_branch=$(git branch --show-current)
        fzf_header='Select the branches to delete'
        set +o errexit
        branches=$(
            git branch --all --color=always --format="${GIT_BRANCH_FORMAT}" |
                grep --invert-match "\[1;32m${current_branch}\*" |
                fzf --ansi --header="${fzf_header}" --multi --no-info |
                awk '{ print $1 }'
        )
        branch_selector_exit_code="${?}"
        set -o errexit
        if [[ ${branch_selector_exit_code} -ne "0" ]]; then
            _failure 'No branches selected'
            return 1
        fi
    fi

    # Confirm that the branches should be deleted.
    echo 'Branches selected:'
    # shellcheck disable=2001
    echo "${branches}" | sed 's/^/\* /'
    echo
    read -p 'Delete these branches (y/n): ' -r response
    while [[ ${response} != 'y' && ${response} != 'n' ]] ; do
        read -p "Please enter either 'y' or 'n': " -r response
    done
    if [[ ${response} != "y" ]]; then
        return 1
    fi

    # Delete the branches.
    exit_code=0
    echo
    for branch in ${branches}; do
        set +o errexit
        if [[ ${branch} =~ '/' ]]; then
            git push --delete --quiet "${branch%/*}" "${branch#*/}"
        else
            git branch --delete --force --quiet "${branch}" &> /dev/null
        fi
        branch_delete_exit_code=${?}
        set -o errexit

        if [[ ${branch_delete_exit_code} = 0 ]]; then
            _success "Branch '${branch}' was deleted"
        else
            _failure "Branch '${branch}' was not deleted"
            exit_code=${branch_delete_exit_code}
        fi
    done

    # Show information.
    _show_local_and_remote_branches 10

    # Exit with a non-zero code if any branches could not be deleted.
    return "${exit_code}"
}


###############################################################################
#
#  Show local and remote branches.
#
#  Arguments:
#    String (optional). A pattern to filter with.
#
###############################################################################
git_branch_list_all() {
    # Get the branches.
    branches=$(git branch --all --color=always --format="${GIT_BRANCH_FORMAT}")

    # Filter the branches if required.
    if [[ ${1-} ]]; then
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
#    String (optional). A pattern to filter with.
#
###############################################################################
git_branch_list_local() {
    # Get the branches.
    branches=$(git branch --color=always --format="${GIT_BRANCH_FORMAT}")

    # Filter the branches if required.
    if [[ ${1-} ]]; then
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
#    String (optional). A pattern to filter with.
#
###############################################################################
git_branch_list_remote() {
    # Get the branches.
    branches=$(
        git branch --color=always --format="${GIT_BRANCH_FORMAT}" --remote
    )

    # Filter the branches if required.
    if [[ ${1-} ]]; then
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
        _warning 'A new branch name is required.'
        return 1
    fi

    # Rename the branch.
    old_branch_name=$(git branch --show-current)
    git branch --move "${1}"
    new_branch_name=$(git branch --show-current)

    # Show information.
    _show_changed_message "${old_branch_name}" "${new_branch_name}"
    _show_local_and_remote_branches 10
}


###############################################################################
#
#  Cherry-pick a commit.
#
#  If no branch or commit is given, fzf is used to select them.
#
#  Arguments:
#    String (optional). Branch or commit.
#
###############################################################################
git_cherry_pick() {
    initial_commit_hash=$(git show --no-patch --format=%h)
    if [[ ${1-} ]]; then
        git cherry-pick "${1}"
    else
        fzf_branch_selector_header='Select the branch to cherry-pick from'
        current_branch=$(git branch --show-current)
        set +o errexit
        branch=$(
            git branch --all --color=always --format="${GIT_BRANCH_FORMAT}" |
                grep --invert-match "\[1;32m${current_branch}\*" |
                fzf --ansi --header="${fzf_branch_selector_header}" --no-info |
                awk '{ print $1 }'
        )
        branch_selector_exit_code="${?}"
        set -o errexit

        if [[ ${branch_selector_exit_code} -ne "0" ]]; then
            _failure 'No branch selected'
            return 1
        fi

        fzf_commit_selector_header='Select the commit to cherry-pick'
        set +o errexit
        commit=$(
            git log --color=always --max-count=50 "${branch}" |
                fzf --ansi --header="${fzf_commit_selector_header}" --no-info |
                awk '{ print $1 }'
        )
        commit_selector_exit_code="${?}"
        set -o errexit

        if [[ ${commit_selector_exit_code} -ne "0" ]]; then
            _failure 'No commit selected'
            return 1
        fi

        git cherry-pick "${commit}"
    fi

    final_commit_hash=$(git show --no-patch --format=%h)

    _show_changed_message "${initial_commit_hash}" "${final_commit_hash}"
    _changes
    _recent_commits
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
    git cherry-pick --abort
    _warning 'Cherry-pick aborted'
    _changes
    _recent_commits
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
    _changes
    _recent_commits
}


###############################################################################
# TODO: Restart here.
###############################################################################
git_clean() {
    git clean --interactive
    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
#
#  Do a Git commit.
#
#  Arguments:
#    String. Commit message (optional).
#
###############################################################################
git_commit() {
    if [[ ${1-} ]]; then
        git commit --message="${*}" --quiet
    else
        git commit --quiet
    fi

    _success 'Done'
    _changes
    _recent_commits
}


###############################################################################
#
#  Amend a Git commit, and optionally change the commit message.
#
#  Arguments:
#    None
#
###############################################################################
git_commit_amend() {
    initial_commit_message=$(git show --no-patch --format=%s)
    git commit --amend --quiet

    echo
    _success 'Commit amended'

    final_commit_message=$(git show --no-patch --format=%s)
    if [[ ${initial_commit_message} != "${final_commit_message}" ]]; then
        echo
        _success "Commit message is now '${final_commit_message}'"
    fi

    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
#
#  Amend a Git commit without changing the commit message.
#
#  Arguments:
#    None
#
###############################################################################
git_commit_amend_reuse_message() {
    if [[ -z $(git_diff_staged) ]]; then
        echo
        _warning 'Nothing staged to commit with'
        _latest_commit
        _changes
        _recent_commits
        return 1
    fi

    git commit --amend --quiet --reuse-message=HEAD

    echo
    _success 'Commit amended'
    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
# TODO
###############################################################################
git_commit_checkpoint() {
    git_commit 'Checkpoint'
}


###############################################################################
# TODO: private function.
###############################################################################
# _choose_commit() {
#     TODO: Make this function to extract code common to the fixup and interactive rebase commands.
    # echo "${response}"
# }


###############################################################################
#
#  Do a Git commit with the --fixup option.
#
#  Arguments:
#    None
#
###############################################################################
git_commit_fixup() {
    if [[ -z $(git_diff_staged) ]]; then
        echo 'Nothing staged to commit.'
        _latest_commit
        _changes
        _recent_commits
        return 1
    fi

    # TODO: Make the max count settable with ${1}.
    fzf_header='Select the commit to fixup'
    commit=$(
        git log --color --max-count=50 |
        fzf --ansi --header="${fzf_header}" --no-info |
        awk '{ print $1 }'
    )

    git commit --fixup="${commit}" --quiet

    commit_message=$(git show --no-patch --format=%s)
    echo
    _success "Committed with message '${commit_message}'"
    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
# TODO
###############################################################################
git_diff() {
    git diff "${@}"
}


# TODO: Add a note that the remote branch is assumed to be "origin", unless
# we're told otherwise.
###############################################################################
# TODO
###############################################################################
git_diff_remote() {
    remote=$(git remote)
    branch=$(git branch --show-current)

    git diff "${remote}/${branch}" "${branch}"
}


###############################################################################
# TODO
###############################################################################
git_diff_staged() {
    git diff --staged
}


###############################################################################
# TODO
###############################################################################
git_diff_unstaged() {
    git diff
}


###############################################################################
# TODO
###############################################################################
git_fetch() {
    git fetch --all --prune
    echo
    git branch --color=always --format="${GIT_BRANCH_FORMAT}" --remote | head -10
}


###############################################################################
# TODO
###############################################################################
git_log() {
    # TODO: Consider removing --graph.
    git log --graph --max-count=10
}


###############################################################################
# TODO
###############################################################################
git_log_all() {
    git log --all --graph
}


###############################################################################
# TODO
###############################################################################
## TODO: Consider removing this function.
git_log_branch() {
    git log --max-count=20
}


###############################################################################
# TODO
###############################################################################
git_merge() {
    # TODO: If there are no parameters, show a fzf list of branches which can
    # be merged.
    git merge "${@}"
    # TODO: Is it worth doing a git status here too?
    echo
    git log --all --max-count=10
    echo
    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
# TODO
###############################################################################
git_pull() {
    git pull --quiet "${@}"
    # TODO: Add a confirmation message with a green tick.
    echo
    # TODO: Is it worth doing a git status here too?
    git log --all --max-count=10
}


###############################################################################
# TODO
###############################################################################
git_push() {
    git push --quiet "${@}"

    # TODO: Show a message with a green tick that the push worked.
    _success 'TODO <count the commits> commits were pushed to <branch>'
    echo
    _latest_commit
    _changes
    _recent_commits
    echo
    git log --all --max-count=10
}


###############################################################################
# TODO
###############################################################################
git_push_force_with_lease() {
    git push --force-with-lease --quiet "${@}"

    # TODO: Show a message with a green tick that the push worked.
    _latest_commit
    _changes
    _recent_commits
    git log --all --max-count=10
}


###############################################################################
#
#  Do a Git rebase.
#
#  Arguments:
#    Strings. The arguments to pass to the Git rebase function.
#
###############################################################################
git_rebase() {
    # TODO: Rename this now that it also does git log?
    current_branch=$(git branch --show-current)

    if [[ ${1-} ]]; then
        target_branch="${1}"
    else
        target_branch=$(
        fzf_header='Select branch to rebase onto'
        git branch --all --color=always --format="${GIT_BRANCH_FORMAT}" |
            fzf --ansi --header="${fzf_header}" --no-info |
            awk '{ print $1 }')
    fi

    git rebase --quiet "${target_branch}"

    echo
    _success "Rebased ${current_branch} onto ${target_branch}"
    echo
    _latest_commit
    _changes
    _recent_commits
    echo
    git log --all --max-count=10  # TODO: Needs to be enough to see all rebased commits.
}


###############################################################################
# TODO
###############################################################################
git_rebase_abort() {
    git rebase --abort

    echo
    _warning 'Rebase aborted'
    echo
    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
# TODO
###############################################################################
git_rebase_continue() {
    git rebase --continue
}


###############################################################################
#
#  Do a Git interactive rebase.
#
#  Arguments:
#    Int. The number of commits to include in the interactive rebase.
#
###############################################################################
git_rebase_interactive() {
    # TODO: If there are unstaged changes, this will fail, so bail out early.
    fzf_header='Select the commit TODO'
    commit=$(
        git log --color --max-count=50 |
            fzf --ansi --header="${fzf_header}" --no-info |
            awk '{ print $1 }'
    )

    git rebase --interactive --quiet "${commit}"

    _latest_commit
    _changes
    _recent_commits
}


###############################################################################
#
#  Do a Git interactive rebase with autosquash.
#
#  Arguments:
#    Int. The number of commits to include in the interactive rebase.
#
###############################################################################
git_rebase_interactive_with_autosquash() {
    fzf_header='Select the commit TODO'
    # TODO: Should this just be --color, or --color=always?
    commit=$(
        git log --color --max-count=50 |
            fzf --ansi --header="${fzf_header}" --no-info |
            awk '{ print $1 }'
    )

    git rebase --autosquash --interactive --quiet "${commit}"

    _latest_commit
    _changes
    _recent_commits
}


# TODO: Bring these back, or not necessary now?
################################################################################
## TODO
################################################################################
#git_reset () {
#    git restore "${@}"

#    if [[ ${exit_code} = 0 ]]; then
        # _latest_commit
        # _changes
        # _recent_commits
#    fi
#}


################################################################################
## TODO
################################################################################
#git_reset_head() {
#    if [[ -z $(git reset --quiet HEAD) ]]; then
#        echo
        # _latest_commit
        # _changes
        # _recent_commits
#    fi
#}


###############################################################################
# TODO
###############################################################################
git_show() {
    git show --format=full
}


###############################################################################
# TODO
###############################################################################
git_stash() {
    git stash "${@}"

    _latest_commit
    _changes
    _recent_commits
}



###############################################################################
# TODO
###############################################################################
git_status() {
    _changes
    # TODO: Colourize the latest commit.
    _latest_commit
}


###############################################################################
#
#  Switch to a Git branch.
#
#  Arguments:
#    Strings. The arguments for the Git switch function.
#
###############################################################################
git_switch() {
    # TODO: Include all remote and local branches, but remove remote branches
    # with local branches from the list?
    if [[ ${1-} ]]; then
        git switch --quiet "${@}"
    else
        # TODO: Remove the current branch from the list?
        fzf_header='TODO: Select ...'
        git branch --color=always --format="${GIT_BRANCH_FORMAT}" |
            fzf --ansi --header="${fzf_header}" --no-info |
            awk '{ print $1 }' |
            xargs git switch --quiet
    fi

    current_branch=$(git branch --show-current)
    # TODO: Handle if the branch isn't actually changed?
    _success "Switched to branch '${current_branch}'"
    echo
    _latest_commit
    _changes
    _recent_commits
}

git_switch_remote() {
    # TODO: Remove remote branches with local branches from the list?
    if [[ ${1-} ]]; then
        git switch --quiet "${@}"
    else
        fzf_header='TODO: Select ...'
        git branch --color=always --format="${GIT_BRANCH_FORMAT}" --remote |
            fzf --ansi --header="${fzf_header}" --no-info |
            awk '{ print $1 }' |
            xargs git switch --quiet
    fi

    current_branch=$(git branch --show-current)
    _success "Switched to branch '${current_branch}'"
    echo
    _latest_commit
    _changes
    _recent_commits
}

###############################################################################
# TODO
###############################################################################
git_unchange () {
    if [[ ${1-} ]]; then
        git restore "${@}"
    else
        git restore .
    fi

    _success "Changes undone"
    # TODO: Work out why this sometimes doesn't execute.
    _changes
    _recent_commits
}


###############################################################################
# TODO
###############################################################################
git_unstage () {
    initial_diff=$(_staged_diff_hash)
    if [[ ${1-} ]]; then
        git restore --staged "${@}"
    else
        git restore --staged .
    fi
    final_diff=$(_staged_diff_hash)

    _show_changed_message "${initial_diff}" "${final_diff}"
    if [[ "${initial_diff}" != "${final_diff}" ]]; then
        _changes
    fi
}


# Private functions.


_latest_commit () {
    echo
    _print_magenta 'Latest commit'
    # TODO: Colourise the git show on the next line?
    git show --no-patch --format='(%h) %s, %ar by %an'
}


_changes() {
    echo
    _print_magenta 'Changes'
    if [[ $(git status --short) ]]; then
        git status --short
    else
        echo '-'
    fi
}


_recent_commits () {
    echo
    _print_magenta 'Latest commits'
    git log --color=always --max-count=5
}

_branch () {
    echo
    _print_magenta 'Branch'
    git branch --show-current
}


###############################################################################
#
#  TODO
#
###############################################################################
_get_files_to_add_with_fzf() {
    fzf_header='Select files to add'
    set +o errexit
    files=$(
        git -c color.ui=always status --short |
            fzf --ansi --header="${fzf_header}" --multi --no-info |
            awk '{ print $2 }'
    )
    branch_selector_exit_code="${?}"
    set -o errexit

    if [[ ${branch_selector_exit_code} -ne "0" ]]; then
        _failure 'No files selected'
        return 1
    fi

    echo "${files}"
}




_print_green() {
    echo -e "${ANSI_GREEN}${1}${ANSI_CLEAR}"
}


_print_grey() {
    echo -e "${ANSI_GREY}${1}${ANSI_CLEAR}"
}


_print_red() {
    echo -e "${ANSI_RED}${1}${ANSI_CLEAR}"
}


_print_yellow() {
    echo -e "${ANSI_YELLOW}${1}${ANSI_CLEAR}"
}


_print_magenta() {
    echo -e "${ANSI_MAGENTA}${1}${ANSI_CLEAR}"
}


_warning() {
    _print_yellow " ${1}"
}

_success() {
    _print_green "🗸 ${1}"
}


_failure() {
    _print_red "✗ ${1}"
}


_local_branches() {
    echo
    _print_magenta 'Local branches'
    git branch --color=always --format="${GIT_BRANCH_FORMAT}"
}


_show_changed_message() {
    if [[ ${1} == "${2}" ]]; then
        _warning 'Nothing done'
    else
        _success 'Done'
    fi
}


_show_local_and_remote_branches() {
    echo
    _print_magenta "Branches"
    branches=$(git branch --all --color=always --format="${GIT_BRANCH_FORMAT}")
    branch_count=$(echo "${branches}" | wc --lines)
    no_of_branches_to_show="${1}"
    if [[ ${branch_count} -le ${no_of_branches_to_show} ]]; then
        echo "${branches}"
    else
        echo "${branches}" | head --lines="${no_of_branches_to_show}"
        trimmed_branch_count=$(( branch_count - no_of_branches_to_show ))
        # TODO: Replace * with ... in the next line?
        _print_grey "* plus ${trimmed_branch_count} more"
    fi
}


_staged_diff_hash() {
    git diff --staged | sha512sum
}


# Run the command
git_${*}
