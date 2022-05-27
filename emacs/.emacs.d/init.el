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
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t))
(package-initialize)

;; Bootstraping use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))

;; Make sure to download packages
(setq use-package-always-ensure t)

(use-package auto-compile
  :config (auto-compile-on-load-mode))

(setq load-prefer-newer t)

(setq user-full-name "Eric Seuret"
      user-mail-address "eric@ericst.ch"
      calendar-week-start-day 1
      calendar-latitude 47.39144
      calendar-longitude 8.0513
      calendar-location-name "Aarau, Switzerland")

(use-package org)
(require 'org)

(setq inhibit-startup-message t
      visible-bell t)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(set-fringe-mode 10)

(global-hl-line-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(column-number-mode 1)

(global-subword-mode 1)

(setq-default fill-column 80)
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'org-mode-hook 'turn-on-auto-fill)

(global-display-line-numbers-mode 1)
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

(setq auto-save-default t)

(use-package one-themes
  :init (load-theme 'one-light t))

(set-face-attribute 'default nil :font "Fira Code")

(setq initial-scratch-message
      (concat ";; Welcome. This is Emacs version " emacs-version
	      " with Org-mode version " org-version ".\n"
	      ";; Happy Hacking!\n"))

(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(use-package which-key
  :config (which-key-mode))

(setq-default cursor-type 'box)

(use-package god-mode
  :bind (("<escape>" . god-local-mode))
  :config
  (defun ese/update-cursor ()
    (setq cursor-type (if (or god-local-mode buffer-read-only)
                          'hollow
                        'box)))
  (add-hook 'god-mode-enabled-hook 'ese/update-cursor)
  (add-hook 'god-mode-disabled-hook 'ese/update-cursor))

(use-package counsel
  :bind (("C-s" . swiper)
         ("M-x" . counsel-M-x)
         ("C-h f" . counsel-describe-function)
         ("C-h v" . counsel-describe-variable)
         ("C-x b" . ivy-switch-buffer))
  :init
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-use-selectable-prompt t)
  (setq recentf-keep '(file-remote-p file-readable-p)))

(use-package ivy-rich
  :after counsel
  :init (ivy-rich-mode 1))

(use-package company
  :hook (after-init . global-company-mode))

(use-package yasnippet
  :after company
  :config  (yas-global-mode 1))

(use-package avy
  :bind (("C-r" . avy-goto-char)))

(use-package hydra
  :config (defhydra hydra-zoom (global-map "<f2>")
	    "Zoom"
	    ("b" text-scale-increase "in")
	    ("s" text-scale-decrease "out")))

(use-package expand-region
  :after (hydra)
  :bind (("C-c e" . 'hydra-expand-region/body))
  :config (defhydra hydra-expand-region (:pre (er/expand-region 1))
            "Expand Region"
            ("e" er/expand-region "expand")
            ("c" er/contract-region "contract")))

(use-package projectile
  :after (counsel)
  :config
  (setq projectile-completion-system 'ivy)
  (projectile-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package counsel-projectile
  :after (counsel projectile)
  :config
  (counsel-projectile-mode t))

(use-package magit
  :bind (("C-c g" . magit-status)))

(use-package move-text
  :config (move-text-default-bindings))

(require 'iso-transl)

(setq org-agenda-files '("~/exocortex/agenda"))

(setq-default org-todo-keywords
              '((sequence "TODO(t!)" "NEXT(n!)" "WAITING(w!)" "FUTURE(f!)" "|" "DONE(d!)" "CANCELED(c!)")))

(setq org-log-into-drawer t)

(bind-key "C-c o c" 'org-capture)

(setq org-capture-templates
      '(("t" "TODO" entry (file+olp "~/exocortex/agenda/main.org" "Inbox")
         "* TODO %?\n %i\n")
        ("l" "Log entry (current buffer)" entry (file+olp+datetree buffer-file-name "Log")
         "* %?\n %i\n")
        ("j" "Journal entry" entry (file+olp+datetree "~/exocortex/journal.org")
         "* %?\n %i\n")))

(bind-key "C-c o a" 'org-agenda)

(setq org-agenda-custom-commands
      '(("a" "Agenda for the current week"
         ((agenda "")
          (todo "NEXT")))
        ("u" "Unscheduled Tasks"
         ((tags-todo "-FUTURE-DEADLINE={.+}-SCHEDULED={.+}")
          (todo "NEXT")))
        ("f" "Future Tasks"
         ((todo "FUTURE")))))

(setq org-refile-use-outline-path 'file)
(setq org-refile-targets '((nil . (:maxlevel . 4))
                           (org-agenda-files . (:maxlevel . 4))))

(setq org-src-window-setup 'current-window)

(add-to-list 'org-structure-template-alist
             '("sel" . "src emacs-lisp"))

(setq org-startup-indented t
      org-ellipsis "⤵")

(use-package org-bullets
  :custom (org-bullets-bullet-list '("◉" "●" "○" "▶" "▹" "●" "○" "▶" "▹" "●" "○" "▶" "▹"))
  :init 
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(use-package dumb-jump
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))

(use-package paredit
  :init (dolist (mode '(emacs-lisp-mode-hook
                        lisp-interaction-mode-hook
                        ielm-mode-hook
                        lisp-mode-hook
                        scheme-mode-hook))
          (add-hook mode (lambda () (paredit-mode 1)))))

(use-package geiser)

(use-package csharp-mode)

(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

(server-start)
