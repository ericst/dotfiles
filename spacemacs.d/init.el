;; -*- mode: emacs-lisp -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.
;; It only loads some different files generated from spacemacs.org. Any
;; modification should go into spacemacs.org.

(defun dotspacemacs/layers ()
  "Configuration Layers declaration.
You should not put any user code in this function besides modifying the variable
values."
  (load-file "~/.spacemacs.d/space-layers.el")
)
(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration.
You should not put any user code in there besides modifying the variable
values."
    (load-file "~/.spacemacs.d/space-init.el")
  )

(defun dotspacemacs/user-init ()
  "Initialization function for user code.
It is called immediately after `dotspacemacs/init'.  You are free to put any
user code."
  (load-file "~/.spacemacs.d/space-uinit.el")
  )

(defun dotspacemacs/user-config ()
  "Configuration function for user code.
 This function is called at the very end of Spacemacs initialization after
layers configuration. You are free to put any user code."
  (load-file "~/.spacemacs.d/space-uconfig.el")
)

;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
