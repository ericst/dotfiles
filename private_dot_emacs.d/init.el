
;; The file ~init.el~ makes sure that ~use-package~ is installed. 

;; On windows, when I compile emacs with MSYS2, I end up with a weird bug
;; where the gnupg homedire is wrongly defined. I found the following to
;; correct that and allows packages to be loaded correctly.


;; [[file:../dotfiles/src/Emacs.org::*Use-package][Use-package:1]]
(if (memq system-type '(windows-nt ms-dos))
    (setq package-gnupghome-dir "~/.emacs.d/elpa/gnupg"))
;; Use-package:1 ends here




;; This installs the MELPA repository and makes sure that ~use-package~
;; installs the package. It is essential to bootstrap on fresh box.
;; Otherwise, ~use-package~ waits until you need a package to download
;; it, which makes for a bad experience when starting on a new box.


;; [[file:../dotfiles/src/Emacs.org::*Use-package][Use-package:2]]
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
;; Use-package:2 ends here



;; Always compile packages, and use the news version available.


;; [[file:../dotfiles/src/Emacs.org::*Use-package][Use-package:3]]
(use-package auto-compile
  :config (auto-compile-on-load-mode))

(setq load-prefer-newer t)
;; Use-package:3 ends here


;; Here are some basic settings such as my identity and location.

;; [[file:../dotfiles/src/Emacs.org::*Personal information][Personal information:1]]
(setq user-full-name "Eric Seuret"
      user-mail-address "eric@ericst.ch"
      calendar-week-start-day 1
      calendar-latitude 47.39144
      calendar-longitude 8.0513
      calendar-location-name "Aarau, Switzerland")
;; Personal information:1 ends here


;; We start by adapting the window by removing what we don't need.

;; - No startup screen
;; - No screaming at me (replace bell with visible flash)
;; - No toolbar
;; - No scroll bar

;; And we add some breathing room to the text content by increasing
;; fringe value.  We also want to start with the frame maximized as Emacs
;; is important.


;; [[file:../dotfiles/src/Emacs.org::*Window and frame][Window and frame:1]]
(setq inhibit-startup-message t
      visible-bell t)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(set-fringe-mode 10)
;; Window and frame:1 ends here


;; Text edition is important. I want to:

;; - Highlight the current line
;; - Show matching parens
;; - Delete and replace selected text
;; - Display columns number by default


;; [[file:../dotfiles/src/Emacs.org::*Edition][Edition:1]]
(global-hl-line-mode 1)
(show-paren-mode 1)
(delete-selection-mode 1)
(column-number-mode 1)
;; Edition:1 ends here




;; Emacs has a smart feature allowing it to redistribute breaks in paragraph to
;; sort of justify it. We want that to happen automatically in certain modes.


;; [[file:../dotfiles/src/Emacs.org::*Edition][Edition:2]]
(setq-default fill-column 80)
(add-hook 'text-mode-hook 'turn-on-auto-fill)
(add-hook 'org-mode-hook 'turn-on-auto-fill)
;; Edition:2 ends here


;; Basically, I want line numbers to be displayed except for org and repl-type
;; modes.


;; [[file:../dotfiles/src/Emacs.org::*Line numbers][Line numbers:1]]
(global-display-line-numbers-mode 1)
(dolist (mode '(org-mode-hook
		term-mode-hook
		shell-mode-hook
		eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))
;; Line numbers:1 ends here


;; Backup files are usefull, but I don't want them to clutter my working
;; directory. So we pack them away in ~\~/.emacs.d/backups~

;; I still need to look at auto-saves.

;; By default auto-save are made into ~/tmp~, which is okay.


;; [[file:../dotfiles/src/Emacs.org::*Backup files and autosave auto asave][Backup files and autosave auto asave:1]]
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

(setq auto-save-default t)
;; Backup files and autosave auto asave:1 ends here


;; I like the ~one-dark~ theme.


;; [[file:../dotfiles/src/Emacs.org::*Theme and font][Theme and font:1]]
(use-package one-themes
  :init (load-theme 'one-dark t))

(set-face-attribute 'default nil :font "Fira Code")
;; Theme and font:1 ends here


;; This makes a rather useful scratch buffer message.


;; [[file:../dotfiles/src/Emacs.org::*Scratch buffer][Scratch buffer:1]]
(setq initial-scratch-message
      (concat ";; Welcome. This is Emacs version " emacs-version
	      " with Org-mode version " org-version ".\n"
	      ";; Happy Hacking!\n"))
;; Scratch buffer:1 ends here


;; This is to make sure org-mode is loaded for the rest of the configuration. Also,
;; we want the last version of org-mode.


;; [[file:../dotfiles/src/Emacs.org::*Loading][Loading:1]]
(use-package org)
(require 'org)
;; Loading:1 ends here


;; When editing code blocks, use the current window rather than poping
;; open a new one.

;; Quickly add source blocks of emacs-lisp with ~C-c C-, el~.


;; [[file:../dotfiles/src/Emacs.org::*Source blocks][Source blocks:1]]
(setq org-src-window-setup 'current-window)

(dolist (element '(("sel" . "src emacs-lisp")
                   ("ssc" . "src scheme")
                   ("sba" . "src bash")))
  (add-to-list 'org-structure-template-alist element))
;; Source blocks:1 ends here


;; I want to have ~org-indent-mode~ on by default. 
;; I also don't want some minor adaptations to the ellipsis.


;; [[file:../dotfiles/src/Emacs.org::*UI adaptation][UI adaptation:1]]
(setq org-startup-indented t
      org-ellipsis "⤵")
;; UI adaptation:1 ends here



;; ~org-bullets~ replaces ~*~ in from headers with nice bullets 

;; [[file:../dotfiles/src/Emacs.org::*UI adaptation][UI adaptation:2]]
(use-package org-bullets
  :custom (org-bullets-bullet-list '("◉" "●" "○" "▶" "▹" "●" "○" "▶" "▹" "●" "○" "▶" "▹"))
  :init 
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))
;; UI adaptation:2 ends here


;; Flyspell is helpful, so we enable it also for comments.

;; [[file:../dotfiles/src/Emacs.org::*Flyspell][Flyspell:1]]
(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)
;; Flyspell:1 ends here


;; ~which-key~ displays some help on available key-bindings chain when in
;; the middle. This helps with discoverability in general.


;; [[file:../dotfiles/src/Emacs.org::*Which-key][Which-key:1]]
(use-package which-key
  :config (which-key-mode))
;; Which-key:1 ends here


;; ~helm~ is a completion framework for emacs. 


;; [[file:../dotfiles/src/Emacs.org::*Helm][Helm:1]]
(use-package helm
  :bind (("M-x"		.	helm-M-x)
	 ("C-x C-f"	.       helm-find-files)
	 ("C-x b"	        .       helm-buffers-list)
	 ("M-i"		.	helm-imenu))
  :init
  (helm-mode 1)
  (setq helm-mode-fuzzy-match			 t
	helm-completion-in-region-fuzzy-match	 t))
;; Helm:1 ends here


;; ~company~ is a general auto-complete framework.  Althought it works
;; quite well out-of-the-box, it does need here and there some
;; specialized backends. Those backends are then configured as need in
;; the languages sections.


;; [[file:../dotfiles/src/Emacs.org::*Company][Company:1]]
(use-package company
  :hook (after-init . global-company-mode))
;; Company:1 ends here


;; ~projectile~ is a project management system for Emacs. 
;; It provide some nice features working from the root of a project.
;; Among those ones:

;; - Jump to a file in project
;; - Compile project
;; - Kill all project buffers
;; - Grep through project
;; - ...

;; The project root is detected either by the presence of a vc file (git,
;; mercurial, ...), or a special package definition file (lein, maven,
;; ...).  Alternatively, you can force it to be a project by creation an
;; empty ~.projectile~ file in the root directory.


;; [[file:../dotfiles/src/Emacs.org::*Project Management][Project Management:1]]
(use-package projectile
  :after (helm)
  :config
  (projectile-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
;; Project Management:1 ends here


;; ~magit~ is a user interface for git.


;; [[file:../dotfiles/src/Emacs.org::*Git porcelain][Git porcelain:1]]
(use-package magit
  :bind (("C-c g" . magit-status)))
;; Git porcelain:1 ends here


;; Allows using of Org-mode's ~M-↑, M-↓~ in other modes too.


;; [[file:../dotfiles/src/Emacs.org::*Moving Text Around][Moving Text Around:1]]
(use-package move-text
  :config (move-text-default-bindings))
;; Moving Text Around:1 ends here


;; For some reason, dead keys don't seem to work properly on my
;; system. The following corrects it on starting emacs. It comes from:
;; [[https://www.emacswiki.org/emacs/DeadKeys][Dead Keys on Emacs Wiki]]


;; [[file:../dotfiles/src/Emacs.org::*Dead Keys][Dead Keys:1]]
(require 'iso-transl)
;; Dead Keys:1 ends here


;; Almost every language comes with a lsp server those days. So we install
;; lsp-mode.


;; [[file:../dotfiles/src/Emacs.org::*lsp-mode][lsp-mode:1]]
(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  :hook ((csharp-mode . lsp)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)
;; lsp-mode:1 ends here


;; ~dumb-jump~ enables "jump to definition" for more than 40 languages.
;; It favors a just working approach by using a grep in the background.

;; Adding it to x-ref allows us to search by using ~M-.~.


;; [[file:../dotfiles/src/Emacs.org::*Jumping to definitions & references][Jumping to definitions & references:1]]
(use-package dumb-jump
  :config
  (add-hook 'xref-backend-functions #'dumb-jump-xref-activate))
;; Jumping to definitions & references:1 ends here


;; For lisps and schemes we basically want paredit mode always on.

;; [[file:../dotfiles/src/Emacs.org::*Lisp & Schemes][Lisp & Schemes:1]]
(use-package paredit
  :init (dolist (mode '(emacs-lisp-mode-hook
                        lisp-interaction-mode-hook
                        ielm-mode-hook
                        lisp-mode-hook
                        scheme-mode-hook))
          (add-hook mode (lambda () (paredit-mode 1)))))

(use-package geiser)
;; Lisp & Schemes:1 ends here


;; Just the basic to be able to edit c# files.


;; [[file:../dotfiles/src/Emacs.org::*C#][C#:1]]
(use-package csharp-mode
      :hook ((csharp-mode . lsp)))
;; C#:1 ends here


;; This is so that I can also develop Vue based frontends.


;; [[file:../dotfiles/src/Emacs.org::*Vue][Vue:1]]
(use-package vue-mode
  :mode "\\.vue\\'"
  :hook ((vue-mode . lsp)))
;; Vue:1 ends here


;; This is to keep my init.el clean. Every customization should go into ~custom.el~


;; [[file:../dotfiles/src/Emacs.org::*Custom file][Custom file:1]]
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)
;; Custom file:1 ends here


;; Even if I don't always use it, I like to have the server started.
;; It comes handy when sometimes I loose the X-Server connection on Emacs under WSL on Windows.

;; [[file:../dotfiles/src/Emacs.org::*Server start][Server start:1]]
(server-start)
;; Server start:1 ends here
