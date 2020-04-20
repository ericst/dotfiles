;;;Eric Seuret's Emacs Configureate
;;;Inspire by: https://sam217pa.github.io/2016/09/02/how-to-build-your-own-spacemacs/


;;Setting package repositories
(require 'package)
(setq package-enable-at-startup nil)
(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages")
	("melpa" . "https://melpa.org/packages/")))

;;Install package
(package-initialize)

;;Bootstrap `use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile
  (require 'use-package))


;;General Settings
(setq inhibit-startup-message t)
(tool-bar-mode -1)
(show-paren-mode 1)

;;Backup files
(setq backup-directory-alist '(("." . "~/emacs.d/backups/")))
(setq backup-by-copying t
      delete-old-versions t
      kept-new-versions 6
      kept-old-versions 2
      version-control t)

;;Auto-Saves
(setq auto-save-default nil)


;;Counsel, Ivy, Swiper
(use-package counsel
  :ensure t
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq ivy-count-format "(%d/%d) ")
  (global-set-key (kbd "C-s") 'swiper-isearch)
  (global-set-key (kbd "M-x") 'counsel-M-x)
  (global-set-key (kbd "C-x C-f") 'counsel-find-file)
  (global-set-key (kbd "M-y") 'counsel-yank-pop)
  (global-set-key (kbd "<f1> f") 'counsel-describe-function)
  (global-set-key (kbd "<f1> v") 'counsel-describe-variable)
  (global-set-key (kbd "<f1> l") 'counsel-find-library)
  (global-set-key (kbd "<f2> i") 'counsel-info-lookup-symbol)
  (global-set-key (kbd "<f2> u") 'counsel-unicode-char)
  (global-set-key (kbd "<f2> j") 'counsel-set-variable)
  (global-set-key (kbd "C-x b") 'ivy-switch-buffer)
  (global-set-key (kbd "C-c v") 'ivy-push-view)
  (global-set-key (kbd "C-c V") 'ivy-pop-view)
  )


;;Base packages
(use-package which-key
  :ensure t
  :config (which-key-mode))

(use-package general
  :ensure t)

(use-package company
  :ensure t
  :hook (after-init . global-company-mode))

(use-package expand-region
  :ensure t
  :config (global-set-key (kbd "C-,") 'er/expand-region))

;; Lisp & Shcheme
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

;;Custom file
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file)

;;Start the server
(server-start)
