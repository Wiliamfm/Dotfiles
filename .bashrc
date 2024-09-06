#
# ~/.bashrc
#

[[ $- == *i* ]] && source /usr/share/blesh/ble.sh --noattach

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls -a --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

alias vim="nvim"
alias wl-recorder='wf-recorder -g "$(slurp)" -f recording.mp4'

export EDITOR=nvim
#tw: This stands for "other writable". Files that are not owned by the current user but are still writable by other users.
LS_COLORS=$LS_COLORS:'tw=0;35:'
#ow: This stands for "own writable". Files that are owned by the current user and are writable.
LS_COLORS=$LS_COLORS:'ow=0;36:' ; export LS_COLORS

#Remove all identical commands in the bash's history.
export HISTCONTROL=erasedups

eval "$(zoxide init --cmd cd bash)"

export PATH="$PATH:$HOME/.dotnet/tools/"

[[ ${BLE_VERSION-} ]] && ble-attach


# Load Angular CLI autocompletion.
source <(ng completion script)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
eval "$(atuin init bash)"
