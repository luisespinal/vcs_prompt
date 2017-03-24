 export TERM=xterm-256color

. ${HOME}/.ctrl.sh

. ${HOME}/.vcsutils.sh

export OLD_PS1="\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$"

export PS1="\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\e[35m\]\`git_prompt\`\e[0m\]\n\$"


