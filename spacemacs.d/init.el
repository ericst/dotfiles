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
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil))))
 '(markup-title-0-face ((t (:inherit markup-gen-face :foreground "sea green" :weight bold :height 1.3))))
 '(markup-title-1-face ((t (:inherit markup-gen-face :foreground "medium sea green" :weight bold :height 1.2))))
 '(markup-title-2-face ((t (:inherit markup-gen-face :foreground "dark olive green" :weight bold :height 1.2))))
 '(markup-title-3-face ((t (:inherit markup-gen-face :foreground "dark olive green" :height 1.1))))
 '(markup-title-4-face ((t (:inherit markup-gen-face :foreground "dark olive green" :slant italic :height 1.1))))
 '(markup-title-5-face ((t (:inherit markup-gen-face :foreground "dark olive green" :underline t :height 1.1)))))
