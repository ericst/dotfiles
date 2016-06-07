;; ---- !!! Warning !!! ----
;; DO NOT MODIFY THIS FILE.
;; It was tangled from the file spacemacs.org.
;; Any modifications should be done there.
;; ---- !!! Warning !!! ----

(evil-leader/set-key "oc" 'org-capture)

(spacemacs/declare-prefix "of" "Filling(Text Align)")
(evil-leader/set-key 
    "ofp" 'fill-paragraph
    "ofs" 'set-fill-column
    "ofa" 'spacemacs/toggle-auto-fill-mode
    "ofi" 'spacemacs/toggle-fill-column-indicator
)

(setq fci-rule-column 81)

(setq backup-directory-alist
    `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
    `((".*" ,temporary-file-directory t)))

(setq auto-mode-alist (append '(("/tmp/mutt.*" . markdown-mode)) auto-mode-alist))

(setq-default org-todo-keywords
    (quote ((sequence "TODO(t!)" "NEXT(n!)" "|" "DONE(x!)")
            (sequence "WAITING(w!)" "HOLD(h!)" "DELEGATED(d!)" "|" "CANCELLED(a!)" )
            (sequence "OPEN(o!)" "|" "CLOSED(c!)")
)))

(setq-default org-todo-keyword-faces
    (quote (("TODO" :foreground "red" :weight bold)
            ("NEXT" :foreground "cyan" :weight bold)
            ("OPEN" :foreground "cyan" :weight bold)
            ("DELEGATED" :foreground "cyan" :weight bold)
            ("WAITING" :foreground "orange" :weight bold)
            ("HOLD" :foreground "magenta" :weight bold)
            ("DONE" :foreground "forest green" :weight bold)
            ("CLOSED" :foreground "forest green" :weight bold)
            ("CANCELLED" :foreground "forest green" :weight bold)
)))

(setq org-agenda-files (quote ("~/org/")))

(setq org-agenda-custom-commands

        '(("p" "Planning"
          ((agenda "")
            (tags "refile" ((org-agenda-overriding-header "Items to refile")))
            (todo "NEXT" ((org-agenda-overriding-header "NEXT Tasks")))
            (todo "TODO" ((org-agenda-overriding-header "TODO Tasks")))))

          ("i" "List of OPEN Issues" todo "OPEN" 
              ((org-agenda-overriding-header "OPEN Issues")))

          ("w" "List of tasks WAITING or on HOLD" todo "HOLD|WAITING" 
              ((org-agenda-overriding-header "Tasks WAITING or on HOLD")))

          ("d" "List of tasks DELEGATED" todo "DELEGATED" 
              ((org-agenda-overriding-header "Tasks DELEGATED")))
))

(setq org-default-notes-file "~/org/refile.org")

(setq org-refile-targets (quote ((nil :maxlevel . 9)
                                 (org-agenda-files :maxlevel . 9))))

(setq org-refile-use-outline-path t)
