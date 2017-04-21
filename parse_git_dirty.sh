function parse_git_dirty {
    status=`git status 2>&1 | tee`

    current=`echo -n "${status}" 2> /dev/null | grep "up-to-date" &> /dev/null; echo "$?"`
    ahead=`echo -n "${status}" 2> /dev/null | grep "is ahead" &> /dev/null; echo "$?"`
    behind=`echo -n "${status}" 2> /dev/null | grep "is behind" &> /dev/null; echo "$?"`
    diverged=`echo -n "${status}" 2> /dev/null | grep "have diverged" &> /dev/null; echo "$?"`

    flags=''

    head_flags=''

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

    ren=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
    del=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
    mod=`echo -n "${status}" 2> /dev/null | grep "mod:" &> /dev/null; echo "$?"`
    new=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
    unt=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`

    mod_flags=''
    ( [ "${ren}" == "0" ] && mod_flags="${mod_flags}r" ) || mod_flags="${mod_flags}-"
    ( [ "${del}" == "0" ] && mod_flags="${mod_flags}d" ) || mod_flags="${mod_flags}-"
    ( [ "${mod}" == "0" ] && mod_flags="${mod_flags}m" ) || mod_flags="${mod_flags}-"
    ( [ "${new}" == "0" ] && mod_flags="${mod_flags}n" ) || mod_flags="${mod_flags}-"
    ( [ "${unt}" == "0" ] && mod_flags="${mod_flags}u" ) || mod_flags="${mod_flags}-"

    [ "${head_flags}x" != "x" ] && flags="${head_flags}|"
    [ "${mod_flags}x"  != "x" ] && flags="${flags}${mod_flags}"

    if [ ! "${flags}" == "" ]; then
        echo " ${flags}"
    else
        echo ""
    fi
}

parse_git_dirty

