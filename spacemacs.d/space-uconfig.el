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

(evil-leader/set-key-for-mode 'org-mode
    "moe" 'org-babel-execute-src-block
    "moi" 'org-toggle-inline-images
)

(setq org-todo-keywords
    (quote ((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d/!)")
            (sequence "WAITING(w@)" "HOLD(h@)" "DELEGATED(p@)" "|" "CANCELLED(a@/!)" )
            (sequence "OPEN(o@)" "|" "CLOSED(c/!)")
)))

(setq org-todo-keyword-faces
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

(setq fci-rule-column 81)

(setq backup-directory-alist
    `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
    `((".*" ,temporary-file-directory t)))
