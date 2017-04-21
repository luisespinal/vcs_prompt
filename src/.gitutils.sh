
function __xgit_exit__() {
    local errcode=${1:-0}
    return ${errcode} 2>/dev/null || exit ${errcode}
}

function ___xgit_stderr___() {
    (>&2 echo "${*}" )
}

function ___xgit_fubar___() {
    ___xgit_stderr___ ${*}
    exit -1
}

function ___xgit_in_git_or_die___() {
    local ST=0
    git branch > /dev/null; ST=$?
    if [ $ST -ne 0 ]
    then
        if [ ! -z "${*}" ]
        then
            ___xgit_stderr___ ${*}
        fi
        exit $ST
    fi
}

function ___xgit_no_args_then_die___() {
    if [ "${#}" -lt 1 ]
    then
        ___xgit_fubar___ "Argument(s) missing"
    fi
}

function xgit_get_upstream() {
    git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

    git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD);
}

function xgit_prune_tags() {
    git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

    git tag -l | xargs git tag -d && git fetch -t;
}

function ___xgit_extract_remote___() {
    local upstream="${1}"
    for x in $(git remote)
    do
        if [[ "${upstream}" =~ ${x}/.* ]]
        then
            echo ${x}
            break
        fi
    done
}

function ___xgit_match_remote_from_suffix___() {
    local upstream=''
    local suffix="${1}"
    local branches=$(set -o pipefail; git branch -r | egrep "${suffix}$" | grep -v -- '->' | wc -l)

    if [ "${branches}" -eq "0" ]
    then
        ___xgit_fubar___ "Cannot guess remote (no remote branch matches for '*/${suffix}')"
    elif [ "${branches}" -gt "1" ]
    then
        ___xgit_fubar___ "Cannot guess remote (${branches} remote branch matches for '*/${suffix}')"
    else
        upstream=$(git branch -r | egrep "${suffix}$" | grep -v -- '->')
    fi

    echo ${upstream}
}

function xgit_update() {
    git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

    local remote=${1}
    local branch=${2}
    local upstream="${remote}/${branch}"

    if [ -z "${branch}" ]
    then
        branch=${1}
        if [ -z "${branch}" ]
        then
            # no name given, try getting upstream from current branch
            upstream=$(get_upstream)
            [ -z "${upstream}" ] && ___fubar___ "Branch has no tracking"
        else
            # treat ${branch} as a suffix and try to match a unique upstream for it
            upstream=$(___xgit_match_remote_from_suffix___ ${branch})
        fi
        remote=$(___xgit_extract_remote___ ${upstream})
    fi

    [ -z "${remote}" ] && ___stderr___ "No remote info, assume local branch."

    [ ! -z "${remote}" ] && git fetch ${remote} --prune -t; 

    git merge --ff-only ${upstream} || git rebase --preserve-merges ${upstream};
}

function xgit_pwd_branch() {
    ___xgit_in_git_or_die___

    git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

    git branch | grep '^\*' | tr -d '*' | tr -d '[:space:]'
}

function xgit_mk_branch() {
    ___xgit_in_git_or_die___
    git branch ${*} && git checkout ${1}
}

function xgit_cd_branch() {
    ___xgit_in_git_or_die___

    local branch="${1}"
    local exit_prompt='<<exit>>'

    if [ -z "${branch}" ]
    then
        branch=""
        ___xgit_stderr___ "Current branch: $(xgit_pwd_branch)"
        PS3='Make a selection [or press ENTER to exit]: '
        select branch in $(git branch --all | tr -d '*' | awk -F' ' '{print $1}'; echo "${exit_prompt}")
        do
            if [[ ! -z "${branch}" ]] && [[ "${branch}" != "${exit_prompt}" ]]
            then

                echo "Switching to ${branch}"
                if [[ ! "${branch}" =~ "remotes/"* ]]
                then
                    git checkout ${branch}
                else
                    b="${branch#remotes/}"
                    remote=$(___xgit_extract_remote___ ${b})
                    b=${b#${remote}/}
                    (set -o pipefail; git branch -l | tr -d '*' | awk '{$1=$1};1' | grep "^${b}$" > /dev/null); ST=$?
                    if [ ${ST} -ne 0 ]
                    then
                        ___xgit_stderr___ "Checking out remote branch ${branch} as ${b}"
                        git checkout ${b}
                    else
                        ___xgit_fubar___ "Cannot checkout remote branch ${branch} - ${b} already checked out. Use plain-vanilla git for this."
                    fi
                fi
            fi
            break;
        done
    fi
}

function ___xgit_get_branches___() {
    local b=''

    for b in $(git branch --all | tr -d '*' | grep -v -- '\->')
    do
        echo ${b}
    done
}

function xgit_inventory() {
    ___xgit_in_git_or_die___

    local b=''

    for b in $( ___xgit_get_branches___ )
    do
        echo ${b}  $(xgit_get_upstream ${b})
    done
}

function ___xgit_check_status_for___() {
    ___xgit_no_args_then_die___ ${*}
    local ST=0
    git status 2>/dev/null | grep -q "${*}" && ST=$?
    echo $ST
}


function xgit_rollback() {
    ___xgit_in_git_or_die___

    local branch="${1}"
    branch="${branch:-$(get_upstream)}"

    local stats=$(___xgit_check_status_for___ "rebase in progress")
    git rebase --abort 
    git reset --hard ${branch}
}

function xgit_clip() {
    ___xgit_in_git_or_die___
    local branch="${1}"
    branch="${branch:-$(get_upstream)}"

    git reset --hard ${branch}
}

function xgit() {
    ___xgit_in_git_or_die___
    ___xgit_no_args_then_die___ ${*}

    local fn="xgit_${1}"
    shift
    "${fn}" ${*}
}

# exec xgit unless the script is being sourced

[[ $0 == "$BASH_SOURCE" ]] && xgit ${*}

