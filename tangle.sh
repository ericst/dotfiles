echo "Running org-babel-tangle-file on $1"
\emacs --batch \
      --eval "(require 'org)" \
      --eval "(org-babel-tangle-file \"$1\")"
