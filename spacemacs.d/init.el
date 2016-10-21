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
 '(ansi-color-faces-vector
   [default bold shadow italic underline bold bold-italic bold])
 '(ansi-color-names-vector
   ["#424242" "#EF9A9A" "#C5E1A5" "#FFEE58" "#64B5F6" "#E1BEE7" "#80DEEA" "#E0E0E0"])
 '(ansi-term-color-vector
   [unspecified "#424242" "#EF9A9A" "#C5E1A5" "#FFEE58" "#64B5F6" "#E1BEE7" "#80DEEA" "#E0E0E0"])
 '(beacon-color "#ec4780")
 '(compilation-message-face (quote default))
 '(evil-emacs-state-cursor (quote ("#E57373" bar)) t)
 '(evil-insert-state-cursor (quote ("#E57373" hbar)) t)
 '(evil-normal-state-cursor (quote ("#FFEE58" box)) t)
 '(evil-visual-state-cursor (quote ("#C5E1A5" box)) t)
 '(evil-want-Y-yank-to-eol t)
 '(fci-rule-color "#20240E" t)
 '(highlight-changes-colors (quote ("#FD5FF0" "#AE81FF")))
 '(highlight-symbol-colors
   (quote
    ("#FFEE58" "#C5E1A5" "#80DEEA" "#64B5F6" "#E1BEE7" "#FFCC80")))
 '(highlight-symbol-foreground-color "#E0E0E0")
 '(highlight-tail-colors (quote (("#ec4780" . 0) ("#424242" . 100))))
 '(magit-diff-use-overlays nil)
 '(nrepl-message-colors
   (quote
    ("#CC9393" "#DFAF8F" "#F0DFAF" "#7F9F7F" "#BFEBBF" "#93E0E3" "#94BFF3" "#DC8CC3")))
 '(package-selected-packages
   (quote
    (solarized-theme inflections cider clojure-mode anaconda-mode auctex anzu iedit smartparens undo-tree yasnippet helm helm-core markdown-mode flycheck projectile magit magit-popup git-commit with-editor async macrostep f dash s yapfify uuidgen typit mmt slime-company py-isort pug-mode org-projectile org-download live-py-mode link-hint insert-shebang hide-comnt git-link flyspell-correct-helm flyspell-correct eyebrowse evil-visual-mark-mode evil-unimpaired evil-ediff eshell-z dumb-jump darkokai-theme company-shell common-lisp-snippets column-enforce-mode clojure-snippets cargo zonokai-theme zenburn-theme zen-and-art-theme yaml-mode xterm-color ws-butler window-numbering which-key web-mode volatile-highlights vi-tilde-fringe use-package underwater-theme ujelly-theme twilight-theme twilight-bright-theme twilight-anti-bright-theme tronesque-theme toxi-theme toml-mode toc-org tao-theme tangotango-theme tango-plus-theme tango-2-theme tagedit sunny-day-theme sublime-themes subatomic256-theme subatomic-theme stekene-theme spacemacs-theme spaceline spacegray-theme soothe-theme soft-stone-theme soft-morning-theme soft-charcoal-theme smyx-theme smooth-scrolling smeargle slime slim-mode shell-pop seti-theme scss-mode sass-mode reverse-theme restart-emacs ranger rainbow-delimiters railscasts-theme racer quelpa pyvenv pytest pyenv-mode py-yapf purple-haze-theme professional-theme popwin planet-theme pip-requirements phoenix-dark-pink-theme phoenix-dark-mono-theme persp-mode pcre2el pastels-on-dark-theme paradox page-break-lines pacmacs orgit organic-green-theme org-repo-todo org-present org-pomodoro org-plus-contrib org-bullets open-junk-file omtose-phellack-theme omnisharp oldlace-theme occidental-theme obsidian-theme noctilux-theme niflheim-theme neotree naquadah-theme mustang-theme multi-term move-text monokai-theme monochrome-theme molokai-theme moe-theme mmm-mode minimal-theme material-theme markdown-toc majapahit-theme magit-gitflow lush-theme lorem-ipsum linum-relative light-soap-theme leuven-theme less-css-mode ledger-mode jbeans-theme jazz-theme jade-mode ir-black-theme inkpot-theme info+ indent-guide ido-vertical-mode hy-mode hungry-delete htmlize hl-todo highlight-parentheses highlight-numbers highlight-indentation heroku-theme hemisu-theme help-fns+ helm-themes helm-swoop helm-pydoc helm-projectile helm-mode-manager helm-make helm-gitignore helm-flyspell helm-flx helm-descbinds helm-css-scss helm-company helm-c-yasnippet helm-ag hc-zenburn-theme gruvbox-theme gruber-darker-theme grandshell-theme gotham-theme google-translate golden-ratio gnuplot gitconfig-mode gitattributes-mode git-timemachine git-messenger gh-md gandalf-theme flycheck-rust flycheck-pos-tip flycheck-ledger flx-ido flatui-theme flatland-theme fish-mode firebelly-theme fill-column-indicator farmhouse-theme fancy-battery expand-region exec-path-from-shell evil-visualstar evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-magit evil-lisp-state evil-indent-plus evil-iedit-state evil-exchange evil-escape evil-args evil-anzu espresso-theme eshell-prompt-extras esh-help emmet-mode elisp-slime-nav dracula-theme django-theme disaster define-word darktooth-theme darkmine-theme darkburn-theme dakrone-theme cython-mode cyberpunk-theme company-web company-statistics company-racer company-quickhelp company-c-headers company-auctex company-anaconda colorsarenice-theme color-theme-sanityinc-tomorrow color-theme-sanityinc-solarized cmake-mode clues-theme clj-refactor clean-aindent-mode clang-format cider-eval-sexp-fu cherry-blossom-theme busybee-theme buffer-move bubbleberry-theme bracketed-paste birds-of-paradise-plus-theme badwolf-theme auto-yasnippet auto-highlight-symbol auto-dictionary auto-compile auctex-latexmk apropospriate-theme anti-zenburn-theme ample-zen-theme ample-theme alect-themes aggressive-indent afternoon-theme adoc-mode adaptive-wrap ace-window ace-link ace-jump-helm-line ac-ispell 2048-game)))
 '(pdf-view-midnight-colors (quote ("#DCDCCC" . "#383838")))
 '(pos-tip-background-color "#3a3a3a")
 '(pos-tip-foreground-color "#9E9E9E")
 '(tabbar-background-color "#353535")
 '(vc-annotate-background nil)
 '(vc-annotate-color-map
   (quote
    ((20 . "#F92672")
     (40 . "#CF4F1F")
     (60 . "#C26C0F")
     (80 . "#E6DB74")
     (100 . "#AB8C00")
     (120 . "#A18F00")
     (140 . "#989200")
     (160 . "#8E9500")
     (180 . "#A6E22E")
     (200 . "#729A1E")
     (220 . "#609C3C")
     (240 . "#4E9D5B")
     (260 . "#3C9F79")
     (280 . "#A1EFE4")
     (300 . "#299BA6")
     (320 . "#2896B5")
     (340 . "#2790C3")
     (360 . "#66D9EF"))))
 '(vc-annotate-very-old-color nil)
 '(weechat-color-list
   (unspecified "#272822" "#20240E" "#F70057" "#F92672" "#86C30D" "#A6E22E" "#BEB244" "#E6DB74" "#40CAE4" "#66D9EF" "#FB35EA" "#FD5FF0" "#74DBCD" "#A1EFE4" "#F8F8F2" "#F8F8F0")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:background nil))))
 '(company-tooltip-common ((t (:inherit company-tooltip :weight bold :underline nil))))
 '(company-tooltip-common-selection ((t (:inherit company-tooltip-selection :weight bold :underline nil))))
 '(markup-meta-face ((t (:stipple nil :foreground "dark gray" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight normal :height 90 :width normal :foundry "unknown" :family "Monospace"))))
 '(markup-meta-hide-face ((t (:inherit markup-meta-face :foreground "dim gray" :height 0.8))))
 '(markup-title-0-face ((t (:inherit markup-gen-face :foreground "sea green" :weight bold :height 1.3))))
 '(markup-title-1-face ((t (:inherit markup-gen-face :foreground "medium sea green" :weight bold :height 1.2))))
 '(markup-title-2-face ((t (:inherit markup-gen-face :foreground "dark olive green" :weight bold :height 1.2))))
 '(markup-title-3-face ((t (:inherit markup-gen-face :foreground "dark olive green" :height 1.1))))
 '(markup-title-4-face ((t (:inherit markup-gen-face :foreground "dark olive green" :slant italic :height 1.1))))
 '(markup-title-5-face ((t (:inherit markup-gen-face :foreground "dark olive green" :underline t :height 1.1)))))
