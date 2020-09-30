;;; guix-manifest.scm -- manifest of basic guix packages
;; Meant to be installed with: ~guix package -m guix-manifest.scm~

(specifications->manifest
 '("stow"
   "font-fira-code"
   "font-fira-mono"
   "font-fira-sans"
   "guile"
   "git"
   "emacs"
   "grep"
   "ripgrep"
   "the-silver-searcher"
   "recutils"
   "aspell"
   "aspell-dict-fr"
   "aspell-dict-en"
   "aspell-dict-es"
   "aspell-dict-de"
   "aspell-dict-ru"))
