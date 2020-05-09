;;; init.el --- Emacs Configuration.

;; Author: Eric Seuret



;;; Comentary:
;; This is ericst's Emacs configuragation file. Feel free to take
;; inspiration from it.

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


;;; General Setings

(setq inhibit-startup-message t)	; No startup screen
(tool-bar-mode -1)			; No toolbar
(scroll-bar-mode -1)			; No scrollbar
(global-hl-line-mode 1)			; Highlight current line
(show-paren-mode 1)			; Show matching parens
(delete-selection-mode 1)		; Delete an replace selected text
(setq column-number-mode t)             ; Display columns numbers by default

;; Backup files
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

;; Auto-Saves
;; TODO: Set it correctly
(setq auto-save-default nil)


;;; Flyspell
(add-hook 'text-mode-hook (lambda () (flyspell-mode 1)))
(add-hook 'prog-mode-hook (lambda () (flyspell-prog-mode 1)))

;;; Core Packages

;; Those package represent the core functionaity of my emacs. They are
;; here mainly for text editing purposes.


;; Which-key displays some help on available keys when one is
;; pressed. This helps with discoverability in general.
(use-package which-key
  :ensure t
  :config (which-key-mode))

;; Company mode is a general auto-complete framework.
(use-package company
  :ensure t
  :hook (after-init . global-company-mode))

;; YASnippet, provides handy snippets
(use-package yasnippet
  :ensure t
  :after company
  :config
  (yas-global-mode 1))

(use-package "xterm-color"
  :ensure t
  :init (require 'eshell)
  :config
  ;; eshell
  (add-hook 'eshell-before-prompt-hook
	    (lambda ()
	      (setq xterm-color-preserve-properties t)))

  (add-to-list 'eshell-preoutput-filter-functions 'xterm-color-filter)
  (setq eshell-output-filter-functions (remove 'eshell-handle-ansi-color eshell-output-filter-functions))
  (setenv "TERM" "xterm-256color")
  (setq compilation-environment '("TERM=xterm-256color"))

  ;; compilation
  (defun my/advice-compilation-filter (f proc string)
    (funcall f proc (xterm-color-filter string)))
  (advice-add 'compilation-filter :around #'my/advice-compilation-filter))

;; Helm augments the interactivity of emacs.
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

;; Hydra allows the creation of sticky-modes.
(use-package hydra
  :ensure t
  :config (defhydra hydra-zoom (global-map "<f2>")
	    "Zoom"
	    ("b" text-scale-increase "in")
	    ("s" text-scale-decrease "out")))

;; Expand region allows selection on steroid. It gradually expands the
;; region by semantic units.
(use-package expand-region
  :ensure t
  :after (hydra)
  :bind (("C-c e" . 'hydra-expand-region/body))
  :config (defhydra hydra-expand-region (:pre (er/expand-region 1))
	    "Expand Region"
	    ("e" er/expand-region "expand")
	    ("c" er/contract-region "contract")))

;;; Projectile

;; Projectile is a project interaction library.
(use-package projectile
  :ensure t
  :bind-keymap ("C-c p" . projectile-command-map)
  :config (projectile-mode 1))

(use-package helm-projectile
  :ensure t
  :after projectile
  :config
  (helm-projectile-on))

;;; Dashboard

;; Displays a dashboard with recent files and projects.
(use-package dashboard
  :ensure t
  :config (progn
	    (dashboard-setup-startup-hook)
	    (setq initial-buffer-choice (lambda () (get-buffer
						    "*dashboard*")))

	    (setq dashboard-center-content t)
	    (setq dashboard-items '((recents . 5)
				    (projects . 5)
				    (registers . 5)))

	    ))

;;; Lisp & Scheme

;; Diverse packages and configuration for lisp and scheme
(use-package paredit
  :ensure t
  :hook ((emacs-lisp-mode . paredit-mode)
	 (lisp-interaction-mode . paredit-mode)
	 (ielm-mode . paredit-mode)
	 (lisp-mode . paredit-mode)
	 (eval-expression-minibuffer-setup . paredit-mode)
	 (scheme-mode . paredit-mode)))

(use-package geiser
  :ensure t)


;;; Outshine

;; Allows to creat sections in code. Kind of like org-mode but as a
;; minor mode. It extends on outline-minor-mode.

;; So far I only use it in lisp-modes but it could be useful to others.

(use-package outshine
  :ensure t
  :hook ((emacs-lisp-mode . outshine-mode)
	 (scheme-mode . outshine-mode)))

;;; C/C++ IDE
;; https://nilsdeppe.com/posts/emacs-c++-ide
(use-package flycheck
  :ensure t
  :config
  (add-hook 'c++-mode-hook
	    (lambda () (setq flycheck-clang-lnguage-standard "c++17")))
  (global-flycheck-mode))

(use-package irony
  :ensure t)

(use-package company-irony
  :ensure t
  :after (company)
  :config
  (add-to-list 'company-backends 'company-irony)
  )


;;; Custom file
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)


;;; Emacs Server
(server-start)
