;;; constra-db.el -*- lexical-binding: t; -*-

(require 'seq)

(defvar constra-db nil
  "Database of Constra contexts.")

(defun constra-db-register (entry)
  "Register Constra context ENTRY."
  (push entry constra-db))

(defun constra-db-reset ()
  "Clear the Constra database."
  (setq constra-db nil))

(defun constra-db-find (context-name)
  "Return the context named CONTEXT-NAME."
  (seq-find
   (lambda (entry)
     (string= context-name
              (plist-get entry :context)))
   constra-db))

(defun constra-db-contexts ()
  "Return names of all registered contexts."
  (mapcar
   (lambda (entry)
     (plist-get entry :context))
   constra-db))

(provide 'constra-db)

;;; constra-db.el ends here
