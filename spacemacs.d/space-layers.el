;; ---- !!! Warning !!! ----
;; DO NOT MODIFY THIS FILE.
;; It was tangled from the file spacemacs.org.
;; Any modifications should be done there.
;; ---- !!! Warning !!! ----

(setq-default 

   ;; Base distribution to use. This is a layer contained in the directory
   ;; `+distribution'. For now available distributions are `spacemacs-base'
   ;; or `spacemacs'. (default 'spacemacs)
   dotspacemacs-distribution 'spacemacs
   ;; List of additional paths where to look for configuration layers.
   ;; Paths must have a trailing slash (i.e. `~/.mycontribs/')
   dotspacemacs-configuration-layer-path '()

   ;; List of additional packages that will be installed without being
   ;; wrapped in a layer. If you need some configuration for these
   ;; packages then consider to create a layer, you can also put the
   ;; configuration in `dotspacemacs/config'.
   dotspacemacs-additional-packages '()
   ;; A list of packages and/or extensions that will not be install and loaded.
   dotspacemacs-excluded-packages '()
   ;; If non-nil spacemacs will delete any orphan packages, i.e. packages that
   ;; are declared in a layer which is not a member of
   ;; the list `dotspacemacs-configuration-layers'. (default t)
   dotspacemacs-delete-orphan-packages t)

(setq-default
   dotspacemacs-configuration-layers
   '(
     ;;Global
     auto-completion
     git
     org
     spell-checking
     syntax-checking
     ;; Lang
     c-c++
     csharp
     python
     html
     rust
     emacs-lisp
     common-lisp
     clojure
     shell-scripts
     yaml
     latex
     asciidoc
     markdown
     ;; Apps
     games
     shell
     ;; Others
     finance
     ranger
     )
  )

(setq-default 
   ;; List of additional packages that will be installed without being
   ;; wrapped in a layer. If you need some configuration for these
   ;; packages then consider to create a layer, you can also put the
   ;; configuration in `dotspacemacs/config'.
   dotspacemacs-additional-packages '(base16-theme)
