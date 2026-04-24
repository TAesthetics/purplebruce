# ═══════════════════════════════════════════════════════════════════════════
#  Powerlevel10k — Cyberpunk Netrunner preset (compact, wizard-free).
#  Two-line prompt. Left: user@host + dir + git. Right: time.
#  Palette: pink 201 · purple 129 · cyan 51 · yellow 226.
# ═══════════════════════════════════════════════════════════════════════════
'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=none
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%F{201}┏━%f'
  typeset -g POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%F{201}┃%f '
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%F{201}┗━❯ %f'
  typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_SUFFIX=
  typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_SUFFIX=

  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs command_execution_time status)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time)

  # context — user@host
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=51
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=201
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n%b@%m'
  typeset -g POWERLEVEL9K_CONTEXT_ALWAYS_SHOW=true

  # dir
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=129
  typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND=129
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=226
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_DIR_MIN_COMMAND_COLUMNS=40
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=60

  # git
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=226
  typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND=201
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND=226
  typeset -g POWERLEVEL9K_VCS_CONFLICTED_FOREGROUND=201
  typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=51

  # status
  typeset -g POWERLEVEL9K_STATUS_OK=false
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=201
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'

  # command execution time
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=3
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=226

  # time (right prompt, live HH:MM:SS)
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=51
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=true

  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
