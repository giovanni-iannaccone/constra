;;; constra-engine.el -*- lexical-binding: t; -*-

(require 'constra-db)
(require 'seq)

(defun constra-engine-format-value (value)
  "Format numeric VALUE."
  (setq value
        (cond
         ((integerp value) value)
         ((numberp value) (truncate value))
         ((stringp value) (string-to-number value))
         (t 0)))
  (format "%d (0x%x)" value value))


(defun constra-engine-group-flags-mask (group)
  "Return the OR of all known values in GROUP.

This is used only for determining which bits are known.
Zero-valued constants do not contribute to the mask."
  (let ((mask 0))
    (dolist (flag (plist-get group :flags) mask)
      (let ((value (cdr flag)))
        (when (> value 0)
          (setq mask
                (logior mask value)))))))


(defun constra-engine-group-exact-match (value group)
  "Return names whose value exactly matches VALUE.

This is useful for composite constants such as STATX_BASIC_STATS."
  (let (result)
    (dolist (flag (plist-get group :flags))
      (when (= value (cdr flag))
        (push (car flag) result)))
    (reverse result)))


(defun constra-engine-group-decode-bitmask (value group)
  "Decode VALUE against bitmask GROUP.

Prefer an exact named constant when one exists.
Otherwise decompose VALUE into known bit flags."
  (let ((exact
         (constra-engine-group-exact-match
          value
          group)))

    (if exact
        exact

      (let (result)
        (dolist (flag (plist-get group :flags))
          (let ((name (car flag))
                (bits (cdr flag)))

            ;; Zero is not a bit and must not participate
            ;; in the decomposition.
            (when (and (> bits 0)
                       (= (logand value bits)
                          bits))
              (push name result))))

        (reverse result)))))


(defun constra-engine-group-decode-enum (value group)
  "Decode VALUE against enum GROUP."
  (let (result)
    (dolist (flag (plist-get group :flags))
      (when (= value (cdr flag))
        (push (car flag) result)))
    (reverse result)))


(defun constra-engine-group-decode-composite (value group)
  "Decode VALUE against composite GROUP.

Composite constants are treated similarly to bitmasks,
but exact matches are preferred."
  (let ((exact
         (constra-engine-group-exact-match
          value
          group)))

    (if exact
        exact

      (let (result)
        (dolist (flag (plist-get group :flags))
          (let ((name (car flag))
                (constant (cdr flag)))

            (when (and (> constant 0)
                       (= (logand value constant)
                          constant))
              (push name result))))

        (reverse result)))))


(defun constra-engine-group-decode (value group)
  "Decode VALUE according to GROUP type."
  (let ((type
         (plist-get group :type)))

    (cond
     ((eq type 'bitmask)
      (constra-engine-group-decode-bitmask
       value
       group))

     ((eq type 'enum)
      (constra-engine-group-decode-enum
       value
       group))

     ((eq type 'composite)
      (constra-engine-group-decode-composite
       value
       group))

     (t
      (constra-engine-group-decode-bitmask
       value
       group)))))


(defun constra-engine-group-expression (decoded)
  "Build an expression from DECODED names."
  (if decoded
      (mapconcat #'identity decoded " | ")
    "0"))


(defun constra-engine-group-unknown (value group)
  "Return unknown bits in VALUE for bitmask GROUP."
  (if (eq (plist-get group :type) 'bitmask)

      (let ((known-mask
             (constra-engine-group-flags-mask
              group)))

        ;; Bits present in VALUE but absent from all
        ;; known flags.
        (logand value
                (lognot known-mask)))

    0))


(defun constra-engine-decode (value group)
  "Decode VALUE according to GROUP."
  (let* ((decoded
          (constra-engine-group-decode
           value
           group))

         (unknown
          (constra-engine-group-unknown
           value
           group)))

    (list
     :name
     (plist-get group :name)

     :type
     (plist-get group :type)

     :flags
     decoded

     :expression
     (constra-engine-group-expression
      decoded)

     :unknown
     unknown)))


(defun constra-engine-decode-groups (value groups)
  "Decode VALUE using GROUPS."
  (mapcar
   (lambda (group)
     (constra-engine-decode
      value
      group))
   groups))


(defun constra-engine-context (value context)
  "Decode VALUE using CONTEXT."
  (let ((groups
         (plist-get context :groups)))

    (when groups
      (list
       :context
       (plist-get context :context)

       :description
       (plist-get context :description)

       :value
       value

       :value-string
       (constra-engine-format-value value)

       :groups
       (constra-engine-decode-groups
        value
        groups)))))


(defun constra-engine-lookup (value &optional context-name)
  "Decode VALUE.

When CONTEXT-NAME is non-nil, only matching contexts
are considered."
  (let (results)

    (dolist (context constra-db)

      (when (or (null context-name)
                (string-match-p
                 context-name
                 (plist-get context :context)))

        (let ((result
               (constra-engine-context
                value
                context)))

          (when result
            (push result results)))))

    (reverse results)))


(defun constra-engine-find-group
    (group-name &optional context-name)
  "Find groups named GROUP-NAME."
  (let (results)

    (dolist (context constra-db)

      (when (or (null context-name)
                (string-match-p
                 context-name
                 (plist-get context :context)))

        (dolist (group
                 (plist-get context :groups))

          (when (string=
                 group-name
                 (plist-get group :name))

            (push group results)))))

    (reverse results)))


(defun constra-engine-decode-group
    (value group-name &optional context-name)
  "Decode VALUE using GROUP-NAME."
  (mapcar
   (lambda (group)
     (let ((result
            (constra-engine-decode
             value
             group)))

       (plist-put
        result
        :value
        value)))

   (constra-engine-find-group
    group-name
    context-name)))


(defun constra-engine-compose-group
    (flag-names group)
  "Compose FLAG-NAMES using GROUP."
  (let ((value 0)
        matched)

    (dolist (flag
             (plist-get group :flags))

      (when (member (car flag)
                    flag-names)

        (push (car flag) matched)

        (setq value
              (logior value
                      (cdr flag)))))

    (setq matched
          (reverse matched))

    (list
     :value value

     :flags matched

     :expression
     (constra-engine-group-expression
      matched))))


(defun constra-engine-compose
    (flag-names &optional context-name)
  "Compose FLAG-NAMES.

When CONTEXT-NAME is supplied, restrict the operation to
that context."
  (let (results)

    (dolist (context constra-db)

      (when (or (null context-name)
                (string-match-p
                 context-name
                 (plist-get context :context)))

        (dolist (group
                 (plist-get context :groups))

          (let* ((composed
                  (constra-engine-compose-group
                   flag-names
                   group))

                 (value
                  (plist-get composed :value))

                 (matched
                  (plist-get composed :flags)))

            (when matched

              (push
               (list
                :context
                (plist-get context :context)

                :group
                (plist-get group :name)

                :value
                value

                :value-string
                (constra-engine-format-value
                 value)

                :flags
                matched

                :expression
                (plist-get composed :expression))

               results))))))

    (reverse results)))


(defun constra-engine-contexts ()
  "Return all registered context names."
  (constra-db-contexts))


(provide 'constra-engine)

;;; constra-engine.el ends here
