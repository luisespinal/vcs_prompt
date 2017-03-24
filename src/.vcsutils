function git_branch_status {
    local status=`git status 2>&1 | tee`

    local current=`echo -n "${status}" 2> /dev/null | grep "up-to-date" &> /dev/null; echo "$?"`
    local ahead=`echo -n "${status}" 2> /dev/null | grep "is ahead" &> /dev/null; echo "$?"`
    local behind=`echo -n "${status}" 2> /dev/null | grep "is behind" &> /dev/null; echo "$?"`
    local diverged=`echo -n "${status}" 2> /dev/null | grep "have diverged" &> /dev/null; echo "$?"`

    local flags=''

    local head_flags=''

    if [ "${diverged}" == "0" ]; then
	head_flags="<>"
    elif [ "${ahead}" == "0" ]; then
	head_flags=">>"
    elif [ "${behind}" == "0" ]; then
	head_flags="<<"
    elif [ "${current}" == "0" ]; then
	head_flags="=="
    else
	head_flags="??"
    fi

    local ren=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
    local del=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
    local mod=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
    local new=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
    local unt=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`

    local mod_flags=''

    if [ "${ren}" == "0" ]; then 
	mod_flags="${mod_flags}r"
    else 
	mod_flags="${mod_flags}-"
    fi

    if [ "${del}" == "0" ]; then 
	mod_flags="${mod_flags}d"
    else 
	mod_flags="${mod_flags}-"
    fi

    if [ "${mod}" == "0" ]; then 
	mod_flags="${mod_flags}m"
    else 
	mod_flags="${mod_flags}-"
    fi

    if [ "${new}" == "0" ]; then mod_flags="${mod_flags}n"; else mod_flags="${mod_flags}-"; fi

    if [ "${unt}" == "0" ]; then mod_flags="${mod_flags}u"; else mod_flags="${mod_flags}-"; fi

    if [ ! -z "${head_flags}" ]; then
	flags="${head_flags}|"
    fi

    if [ ! -z "${mod_flags}" ]; then
	flags="${flags}${mod_flags}"
    fi

    if [ ! -z "${flags}" ]; then
	echo "[${flags}]"
    else
	echo ""
    fi
}

function git_stash_status() {
        local cnt="$(git stash list | wc -l)"
	( [ "${cnt}" -gt "0" ] && echo "[stash=${cnt}]" ) || echo ""
}

function git_prompt() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]
    then
	    BRANCH="${BRANCH} $(git_branch_status) $(git_stash_status)"
        printf "\n >> git:${BRANCH}"
    else
        echo ""
    fi
}

