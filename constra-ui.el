;;; constra-ui.el --- Constra user interface -*- lexical-binding: t; -*-

(require 'seq)

(require 'constra-db)
(require 'constra-engine)
(require 'linux-generated nil t)

(defconst constra-ui-prompt-prefix "Constra › "
  "Prefix used by Constra minibuffer prompts.")

(defun constra-ui-prompt (prompt &optional context group)
  "Build a Constra PROMPT."
  (concat
   constra-ui-prompt-prefix
   (when context
     (format "%s › " context))
   (when group
     (format "%s › " group))
   prompt))

(defun constra-ui-context ()
  "Read a Constra context."
  (completing-read
   (constra-ui-prompt "Context: ")
   (constra-engine-contexts)
   nil
   t))

(defun constra-ui-groups (&optional context)
  "Return available groups, optionally restricted to CONTEXT."
  (delete-dups
   (mapcar
    (lambda (group)
      (plist-get group :name))
    (apply #'append
           (mapcar
            (lambda (entry)
              (when (or (null context)
                        (string= context
                                 (plist-get entry :context)))
                (plist-get entry :groups)))
            constra-db)))))

(defun constra-ui-group (&optional context)
  "Read a Constra group."
  (completing-read
   (constra-ui-prompt "Group: " context)
   (constra-ui-groups context)
   nil
   t))

(defun constra-ui-format-result (result)
  "Format decoded RESULT."
  (let ((description (plist-get result :description))
        (value (plist-get result :value-string))
        (expression (plist-get result :expression))
        (unknown (plist-get result :unknown)))
    (concat
     (when description
       (format "\n%s" description))

     (when value
       (format "\nValue       %s" value))

     (format "\nExpression  %s"
             (or expression "0"))

     (when (and unknown (> unknown 0))
       (format "\nUnknown     0x%x" unknown)))))

(defun constra-ui-format-lookup-context (result)
  "Format lookup RESULT."
  (let ((context (plist-get result :context))
        (description (plist-get result :description))
        (groups (plist-get result :groups)))
    (concat
     context

     (when description
       (format "\n%s" description))

     (when groups
       (format
        "\n\n%s"
        (mapconcat
         #'constra-ui-format-result
         groups
         "\n\n"))))))

;;;###autoload
(defun constra-lookup ()
  "Decode a numeric constant in a selected context."
  (interactive)
  (let* ((context (constra-ui-context))
         (value
          (read-number
           (constra-ui-prompt "Constant: " context)))
         (results
          (constra-engine-lookup value context)))

    (if results
        (message
         "%s › %s\n\n%s"
         context
         value
         (mapconcat
          #'constra-ui-format-lookup-context
          results
          "\n\n"))
      (user-error
       "Constra: no match for %s in %s"
       value
       context))))

(defun constra-ui-group-flags (group &optional context)
  "Return flags belonging to GROUP."
  (let ((groups (constra-engine-find-group group context)))
    (when groups
      (plist-get (car groups) :flags))))

(defun constra-ui-flag-value (name flags)
  "Return the numeric value of NAME from FLAGS."
  (cdr (assoc name flags)))

(defun constra-ui-compose-value (names flags)
  "Compose NAMES using FLAGS."
  (let ((value 0))
    (dolist (name names value)
      (setq value
            (logior value
                    (constra-ui-flag-value name flags))))))

(defun constra-ui-read-flags (group context)
  "Interactively select multiple flags from GROUP."
  (let* ((flags (constra-ui-group-flags group context))
         (names (mapcar #'car flags))
         selected
         done)

    (while (not done)
      (let* ((value (constra-ui-compose-value selected flags))
             (prompt (format "Flags [Value: %d (0x%x)] "
                             value value))
             (available
              (seq-remove
               (lambda (name)
                 (member name selected))
               names))
             (choice
              (completing-read
               prompt
               available
               nil
               nil)))

        (if (string= choice "")
            (setq done t)
          (push choice selected))))

    (reverse selected)))

(defun constra-ui-format-compose (result flags)
  "Format composed RESULT and selected FLAGS."
  (let* ((group (plist-get result :group))
         (context (plist-get result :context))
         (expression (plist-get result :expression))
         (value (plist-get result :value-string))
         (group-flags (constra-ui-group-flags group context)))
    (format
     "%s\nGroup: %s\nValue: %s\nExpression: %s\n\nConstants:\n%s"
     context
     group
     value
     expression
     (mapconcat
      (lambda (name)
        (let ((number
               (constra-ui-flag-value
                name
                group-flags)))
          (format " %s = %d (0x%x)"
                  name number number)))
      flags
      "\n"))))

;;;###autoload
(defun constra-compose ()
  "Compose multiple constants into a numeric value."
  (interactive)
  (let* ((context (constra-ui-context))
         (group (constra-ui-group context))
         (flags (constra-ui-read-flags group context))
         (results (and flags
                       (constra-engine-compose flags context)))
         (result
          (seq-find
           (lambda (entry)
             (string= group
                      (plist-get entry :group)))
           results)))

    (cond
     ((null flags)
      (message "Constra: no flags selected"))

     (result
      (message "%s"
               (constra-ui-format-compose result flags)))

     (t
      (message "Constra: no matching flags")))))

(defun constra-ui-format-context (context)
  "Format CONTEXT."
  (let ((name (plist-get context :context))
        (description (plist-get context :description))
        (groups (plist-get context :groups)))

    (concat
     name

     (when description
       (format "\n%s" description))

     (when groups
       (format
        "\n\nGroups:\n%s"
        (mapconcat
         (lambda (group)
           (format
            "  %-32s [%s] (%d constants)"
            (plist-get group :name)
            (plist-get group :type)
            (length (plist-get group :flags))))
         groups
         "\n"))))))

;;;###autoload
(defun constra-describe-context ()
  "Display all groups belonging to a context."
  (interactive)
  (let* ((name (constra-ui-context))
         (context
          (seq-find
           (lambda (entry)
             (string= name
                      (plist-get entry :context)))
           constra-db)))

    (if context
        (message
         "%s"
         (constra-ui-format-context context))
      (user-error
       "Constra: context not found: %s"
       name))))

(provide 'constra-ui)

;;; constra-ui.el ends here
