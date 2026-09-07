# 沿用日常 Mac 的 Oh My Zsh 主题与 Git/fzf 快捷键；基础镜像不写入身份或仓库规则。
export ZSH=/opt/oh-my-zsh
ZSH_THEME="robbyrussell"
zstyle ':omz:update' mode disabled
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)
source "$ZSH/oh-my-zsh.sh"

# 历史记录保存在用户主目录，并在交互会话间共享、去重。
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY
bindkey -e

# 用 apt 提供的 fdfind 加速 fzf 文件搜索，配合目录跳转和常用终端快捷命令。
export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fdfind --type d --hidden --exclude .git'
eval "$(zoxide init zsh)"

alias ll='eza -lah --group-directories-first'
alias lt='eza --tree --level=2'
alias lg='lazygit'
