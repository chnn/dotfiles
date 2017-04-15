function cd
  builtin cd $argv
  set -U LAST_DIR (pwd)
end
