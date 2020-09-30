;;; init.el --- Emacs Configuration.
;; Author: Eric Seuret

;;; Commentary:
;; This file only bootstraps use-package and loads the org configuration file.

;;; Code:

;;; MELPA & use-package
;; Installing MELPA
(require 'package)
(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  (when no-ssl (warn "\
Your version of Emacs does not support SSL connections,
which is unsafe because it allows man-in-the-middle attacks.
There are two things you can do about this warning:
1. Install an Emacs version that does support SSL and be safe.
2. Remove this warning from your init file so you won't see it again."))
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  )
(package-initialize)

;; Bootstraping use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

;;; Load Org Configuration
;; As my configuration will be symlinked by stow.
;; It is better to follow the symlinked files.
(setq vc-follow-symlinks t)
(org-babel-load-file "~/.emacs.d/configuration.org")

(provide 'init)
;;; init.el ends here
