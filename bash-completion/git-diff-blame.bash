__GIT_DIFF_BLAME_PRINT_WARNING_ON_TOO_EARLY_OPTIONS="${__GIT_DIFF_BLAME_PRINT_WARNING_ON_TOO_EARLY_OPTIONS:-1}"
__GIT_DIFF_BLAME_VERBOSE_FAILURES="${__GIT_DIFF_BLAME_VERBOSE_FAILURES:-0}"

__git_diff_blame_warnings_too_early_options () {
  [ "$__GIT_DIFF_BLAME_PRINT_WARNING_ON_TOO_EARLY_OPTIONS" == "true" ] || (( $__GIT_DIFF_BLAME_PRINT_WARNING_ON_TOO_EARLY_OPTIONS != 0 ))
}


__git_diff_blame_verbose_failures () {
  [ "$__GIT_DIFF_BLAME_VERBOSE_FAILURES" == "true" ] || (( $__GIT_DIFF_BLAME_VERBOSE_FAILURES != 0 ))
}

# It would have been nice if these could be shorter, but more concise name are far more likely to clash...
__git_diff_blame_is_function() {
  if __git_diff_blame_verbose_failures; then
    test "$(type -t "$1")" == "function"
  else
    test "$(type -t "$1" 2> /dev/null)" == "function"
  fi
}

# If git completions aren't loaded yet, ask for them now
if ! __git_diff_blame_is_function _git_diff; then
  if __git_diff_blame_verbose_failures; then
    { __load_completion git && is_defined_and_function _git_diff; } || {
    # Is stderr being printed into a terminal?
    test -t 2 && printf "Cannot find or load git's bash_completion library, completions for git-diff-blame may fail.\n" >&2; }
  else
    __load_completion git
  fi
fi

__git_diff_blame_count_arguments() {
    # Somewhat annoyingly for this case, __git_count_arguments resets to 0
    # on encountering '--' exactly.
    # So to get an accurate count, we don't let __git_count_arguments "see"
    # '--' as the last element, and add 1 ourself

    # But only if git's completions uses _get_comp_words_by_ref

    # Surrounding the string to check with x's prevents weird edge cases.
    # Especially involving empty strings.
    if [[ x"$cur"x == 'x--x' ]]; then
      # save old bash_complition state
      local -a old_words=("${words[@]}")
      local old_cword="$cword"
      local old_prev="$prev"
      # We know this should be '--' based on our if condition, but doesn't
      # hurt to be extra safe.
      local old_cur="$cur"

      cur="$prev"
      # cword is the index of the last element, one below the total length
      #
      words=("${words[@]:0:$cword}")
       (( --cword ))
      # Not safe to assume bash 4.1 or up, so we can't use negative indexes.
      prev="${words[$cword]}"

      local actual_count="$(__git_count_arguments "$@")"
      local _count_args_ret=$?
      (( ++_actual_count ))

      # restore old state
      words=("${old_words[@]}")
      cword="$old_cword"
      prev="$old_prev"
      cur="$old_cur"

      printf "%d" "$actual_count"
      return $_count_args_ret
    else
      __git_count_arguments "$@"
    fi
}

_git_diff_blame() {
  # git-diff options can only happen after the two refspecs are given.

  # We are going to be trying to use some possibly not public API.
  # So that is why we need to be so careful with whether functions are defined.

  # Remeber, cword is the index, so it should always be non-empty.
  # The "cword" check is so we don't start printing the warnings after a '--' for diff.
  if \
      [[ -n "$cword" && "$cword" < 4 && -t 2 \
        && (x"$cur"x == 'x-x' || x"$cur"x == 'x-?x' \
        || x"$cur"x == 'x--x' || x"$cur"x == 'x--?x') \
      ]] \
      && __git_diff_blame_warnings_too_early_options \
      && __git_diff_blame_is_function __git_count_arguments
    then
    # Warn if argument options too early, but only if up to one letter given
    # (to avoid printing the warning too much).
    local args_count="$(__git_diff_blame_count_arguments diff-blame)"
    local args_get_ret=$?
    if (( $args_get_ret == 0 && $args_count < 2 )); then
      printf "\n%s: Warning: First two arguments to git diff-blame must be the before and after revspecs, with 'git diff' options coming after.\n" "git-diff-blame-completion" >&2
    fi
  fi
  # Delegate to regular git diff
  _git_diff
}

# __git_complete_command, and this the completion for git diff-blame, should be able to find the above automatically
