C_RESET='\[\033[00m\]'
C_RED='\[\033[01;31m\]'
C_GREEN='\[\033[01;32m\]'
C_BLUE='\[\033[01;34m\]'
C_MAGENTA='\[\033[01;35m\]'

if [ "$(id -u)" -eq 0 ]; then 
    C_USER=$C_MAGENTA
    PS_SIGN="#"
else
    C_USER=$C_GREEN
    PS_SIGN="\$"
fi

PS1="${C_USER}\u@\h${C_RESET}:${C_BLUE}\w${C_RESET}${PS_SIGN} "

if [ -n "$SSH_CONNECTION" ]; then
    PS1="${C_RED}[REMOTE] $PS1"
fi

unset C_RESET C_RED C_GREEN C_BLUE C_MAGENTA C_USER PS_SIGN
