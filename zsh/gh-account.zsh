# gh as the personal account under ~/albindahlberg/, the active account elsewhere.
# Pairs with git/personal.gitconfig, which does the same for git push/pull.
gh() {
  case $PWD/ in
    $HOME/albindahlberg/*) GH_TOKEN=$(command gh auth token --user albindahlberg) command gh "$@" ;;
    *) command gh "$@" ;;
  esac
}
