function ___stderr___() {
	(>&2 echo "$*" )
}

function ___fubar___() {
	___stderr___ $*
	exit -1
}

function ___in_git_or_die___() {
	git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;
}

function get_upstream() {
	git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

	git for-each-ref --format='%(upstream:short)' $(git symbolic-ref -q HEAD);
}

function prune_tags() {
	git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

	git tag -l | xargs git tag -d && git fetch -t; 
}

function ___extract_remote___() {
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

function ___match_remote_from_suffix___() {
	local upstream=''
	local suffix="${1}"
	local branches=$(set -o pipefail; git branch -r | egrep "${suffix}$" | grep -v -- '->' | wc -l)

	if [ "${branches}" -eq "0" ]
	then
		___fubar___ "Cannot guess remote (no remote branch matches for '*/${suffix}')"
	elif [ "${branches}" -gt "1" ]
	then
		___fubar___ "Cannot guess remote (${branches} remote branch matches for '*/${suffix}')"
	else
		upstream=$(git branch -r | egrep "${suffix}$" | grep -v -- '->')
	fi
	
	echo ${upstream}	
}

function update() {
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
			upstream=$(___match_remote_from_suffix___ ${branch})
		fi
		remote=$(___extract_remote___ ${upstream})
	fi
	
	[ -z "${remote}" ] && ___stderr___ "No remote info, assume local branch."

	[ ! -z "${remote}" ] && git fetch ${remote} --prune -t; 

	git merge --ff-only ${upstream} || git rebase --preserve-merges ${upstream};
}

function pwd_branch() {
	___in_git_or_die___

	git branch > /dev/null; ST=$?; if [ $ST -ne 0 ]; then exit $ST; fi;

	git branch | grep '^\*' | tr -d '*' | tr -d '[:space:]'
}

function mk_branch() {
	___in_git_or_die___
	git branch ${*} && git checkout ${1}
}

function cd_branch() {
	___in_git_or_die___

	local branch="${1}"
	
	if [ -z "${branch}" ]
	then
		branch=""
		___stderr___ "Current branch: $(pwd_branch)"
		select branch in $(git branch --all | tr -d '*' | awk -F' ' '{print $1}')
		do
			if [[ ! -z "${branch}" ]]
			then
				break
			fi
		done
	fi

	if [[ ! "${branch}" =~ "remotes/"* ]]
	then
		git checkout ${branch}	
	else
		b="${branch#remotes/}"
		remote=$(___extract_remote___ ${b})
		b=${b#${remote}/}
		(set -o pipefail; git branch -l | tr -d '*' | awk '{$1=$1};1' | grep "^${b}$" > /dev/null); ST=$?
		if [ ${ST} -ne 0 ]
		then
			___stderr___ "Checking out remote branch ${branch} as ${b}"
			git checkout ${b}
		else
			___fubar___ "Cannot checkout remote branch ${branch} - ${b} already checked out. Use plain-vanilla git for this."
		fi
	fi
}


function rollback() {
	___in_git_or_die___

	local branch="${1}"
	branch="${branch:-$(get_upstream)}"
	
	git rebase --abort 
	git reset --hard ${branch}
}

