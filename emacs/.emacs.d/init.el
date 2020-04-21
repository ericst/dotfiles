;;; init.el --- Emacs Configuration. 

;; Author: Eric Seuret

;; This is ericst's Emacs configuragation file. Feel free to take
;; inspiration from it.


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


;;; General Setings

(setq inhibit-startup-message t)
(tool-bar-mode -1)
(show-paren-mode 1)

;; Backup files
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

;; Auto-Saves
(setq auto-save-default nil)


;;; Core Packages
(use-package which-key
  :ensure t
  :config (which-key-mode))

(use-package company
  :ensure t
  :hook (after-init . global-company-mode))

(use-package helm
  :ensure t
  :init (require 'helm-config)
  :bind (("M-x" . 'helm-M-x)
	 ("M-y" . 'helm-show-kill-ring)
	 ("C-x C-f" . 'helm-find-files)
	 ("C-h d" . 'helm-info-at-point)
	 ("C-h i" . 'helm-info)
	 ("C-x C-d" . 'helm-browse-project)
	 ("C-h C-f" . 'helm-apropos)
	 ("C-h a" . 'helm-apropos)
	 ("C-h C-d" . 'helm-debug-open-last-log))
  :config (helm-mode 1))

(use-package hydra
  :ensure t
  :config (defhydra hydra-zoom (global-map "<f2>")
	    "Zoom"
	    ("b" text-scale-increase "in")
	    ("s" text-scale-decrease "out")))

(use-package outshine
  :ensure t)

(use-package expand-region
  :ensure t
  :after (hydra)
  :bind (("C-c e" . 'hydra-expand-region/body))
  :config (defhydra hydra-expand-region (:pre (er/expand-region 1))
	    "Expand Region"
	    ("e" er/expand-region "expand")
	    ("c" er/contract-region "contract")))


;;; Lisp & Scheme
(use-package paredit
  :ensure t
  :config
  (add-hook 'emacs-lisp-mode-hook #'paredit-mode)
  (add-hook 'lisp-interaction-mode-hook #'paredit-mode)
  (add-hook 'ielm-mode-hook #'paredit-mode)
  (add-hook 'lisp-mode-hook #'paredit-mode)
  (add-hook 'eval-expression-minibuffer-setup-hook #'paredit-mode)
  (add-hook 'scheme-mode-hook #'paredit-mode))

(use-package geiser) 


;;; Custom file & settings
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)


;;; Emacs Server
(server-start)
