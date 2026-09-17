;;; constra-generator.el --- Generate Constra databases -*- lexical-binding: t; -*-

(require 'constra-db)
(require 'seq)
(require 'subr-x)

(defgroup constra-generator nil
  "Generate Constra databases."
  :group 'constra)

(defcustom constra-generator-output-directory
  (expand-file-name
   "data/generated"
   (file-name-directory
    (or load-file-name buffer-file-name)))
  "Directory for generated databases."
  :type 'directory
  :group 'constra-generator)

(defcustom constra-generator-compiler
  "cc"
  "C compiler used to preprocess Linux headers."
  :type 'string
  :group 'constra-generator)

(defcustom constra-generator-cflags
  '("-std=gnu11")
  "Extra flags passed to the C compiler."
  :type '(repeat string)
  :group 'constra-generator)

(defvar constra-generator-contexts nil
  "Contexts registered with the generator.")

(defun constra-generator-register-context (context)
  "Register CONTEXT."
  (push context constra-generator-contexts))

(defun constra-generator--header-path (header)
  "Return filesystem path for HEADER when it exists.

This is mainly useful for diagnostics.  The actual preprocessing is
performed by the compiler so that its native include search paths and
architecture configuration are respected."
  (let ((dirs
         '("/usr/include"
           "/usr/local/include"
           "/usr/include/x86_64-linux-gnu"
           "/usr/include/aarch64-linux-gnu"
           "/usr/include/arm-linux-gnueabihf")))
    (seq-some
     (lambda (dir)
       (let ((file (expand-file-name header dir)))
         (when (file-readable-p file)
           file)))
     dirs)))

(defun constra-generator--preprocess-headers (headers)
  "Return preprocessor macro definitions for HEADERS.

HEADERS are included by the compiler using -include.  The compiler's
own include paths, predefined macros and architecture are therefore
used."
  (unless (executable-find constra-generator-compiler)
    (error
     "Constra: compiler not found: %s"
     constra-generator-compiler))

  (with-temp-buffer
    (let* ((args
            (append
             constra-generator-cflags
             '("-dM" "-E" "-P")
             (mapcan
              (lambda (header)
                (list "-include" header))
              headers)
             '("-")))
           (exit-code
            (apply #'call-process
                   constra-generator-compiler
                   nil
                   (current-buffer)
                   nil
                   args)))

      (unless (and (integerp exit-code)
                   (zerop exit-code))
        (error
         "Constra: preprocessing failed for %s (exit=%s)"
         (mapconcat #'identity headers ", ")
         exit-code))

      (buffer-string))))

(defun constra-generator--parse-defines (text)
  "Return NAME/VALUE pairs from preprocessor output TEXT.

Function-like macros are ignored.  Only object-like macros are returned."
  (let (result)
    (dolist (line (split-string text "\n" t))
      (when
          (string-match
           "^[ \t]*#[ \t]*define[ \t]+\\([A-Za-z_][A-Za-z0-9_]*\\)[ \t]+\\(.+\\)$"
           line)
        (let ((name (match-string 1 line))
              (value (string-trim
                      (match-string 2 line))))
          (push (cons name value) result))))

    (nreverse result)))

(defun constra-generator--collect-defines (headers)
  "Read HEADERS through the C preprocessor."
  (message
   "Constra: preprocessing %s..."
   (mapconcat #'identity headers ", "))

  (constra-generator--parse-defines
   (constra-generator--preprocess-headers headers)))

(defun constra-generator--selected-p (name prefixes includes)
  "Return non-nil when NAME is selected."
  (or
   (member name includes)

   (seq-some
    (lambda (prefix)
      (string-prefix-p prefix name))
    prefixes)))

(defun constra-generator--select (defines prefixes includes)
  "Select matching DEFINES."
  (seq-filter
   (lambda (entry)
     (constra-generator--selected-p
      (car entry)
      prefixes
      includes))
   defines))

(defun constra-generator--strip-integer-suffix (value)
  "Remove C integer suffixes from VALUE."
  (replace-regexp-in-string
   "[uUlLzZ]+\\'"
   ""
   value))

(defun constra-generator--parse-number (value)
  "Parse C integer VALUE.

Return a Lisp integer or nil.

Supports:
- decimal integers
- hexadecimal integers
- octal integers
- binary integers
- optional C integer suffixes such as U, L, UL, ULL."
  (setq value
        (string-trim value))

  (setq value
        (replace-regexp-in-string
         "[uUlLzZ]+\\'"
         ""
         value))

  (cond
   ((string-match
     "\\`\\([-+]\\)?0[xX]\\([0-9a-fA-F]+\\)\\'"
     value)
    (let ((sign (match-string 1 value))
          (digits (match-string 2 value)))
      (let ((number (string-to-number digits 16)))
        (if (equal sign "-")
            (- number)
          number))))

   ((string-match
     "\\`\\([-+]\\)?0[bB]\\([01]+\\)\\'"
     value)
    (let ((sign (match-string 1 value))
          (digits (match-string 2 value)))
      (let ((number (string-to-number digits 2)))
        (if (equal sign "-")
            (- number)
          number))))

   ((string-match
     "\\`\\([-+]\\)?0\\([0-7]+\\)\\'"
     value)
    (let ((sign (match-string 1 value))
          (digits (match-string 2 value)))
      (let ((number (string-to-number digits 8)))
        (if (equal sign "-")
            (- number)
          number))))
   
   ((string-match-p
     "\\`[-+]?[0-9]+\\'"
     value)
    (string-to-number value 10))

   (t
    nil)))

(defun constra-generator--tokenize-expression (expression)
  "Tokenize C integer EXPRESSION.

Return a list of strings or nil when the expression contains
unsupported syntax."
  (let ((pos 0)
        (len (length expression))
        tokens
        failed)

    (while (< pos len)
      (cond
       ((string-match
         "\\`[ \t\n\r]+"
         (substring expression pos))
        (setq pos
              (+ pos
                 (length
                  (match-string 0
                                (substring expression pos))))))

       ((string-match
         "\\`\\(<<\\|>>\\)"
         (substring expression pos))
        (push (match-string 1 (substring expression pos))
              tokens)
        (setq pos
              (+ pos
                 (length
                  (match-string 1
                                (substring expression pos))))))

       ((string-match
         "\\`[()|&^~+*/%-]"
         (substring expression pos))
        (push (match-string 0 (substring expression pos))
              tokens)
        (setq pos (1+ pos)))

       ((string-match
         "\\`0[xX][0-9a-fA-F]+[uUlLzZ]*"
         (substring expression pos))
        (push (match-string 0 (substring expression pos))
              tokens)
        (setq pos
              (+ pos
                 (length
                  (match-string 0
                                (substring expression pos))))))

       ((string-match
         "\\`0[bB][01]+[uUlLzZ]*"
         (substring expression pos))
        (push (match-string 0 (substring expression pos))
              tokens)
        (setq pos
              (+ pos
                 (length
                  (match-string 0
                                (substring expression pos))))))

       ((string-match
         "\\`[0-9]+[uUlLzZ]*"
         (substring expression pos))
        (push (match-string 0 (substring expression pos))
              tokens)
        (setq pos
              (+ pos
                 (length
                  (match-string 0
                                (substring expression pos))))))

       ((string-match
         "\\`[A-Za-z_][A-Za-z0-9_]*"
         (substring expression pos))
        (push (match-string 0 (substring expression pos))
              tokens)
        (setq pos
              (+ pos
                 (length
                  (match-string 0
                                (substring expression pos))))))

       (t
        (setq failed t)
        (setq pos len))))

    (unless failed
      (nreverse tokens))))

(defun constra-generator--binary-precedence (operator)
  "Return precedence for binary OPERATOR."
  (cond
   ((member operator '("*" "/" "%")) 60)
   ((member operator '("+" "-")) 50)
   ((member operator '("<<" ">>")) 40)
   ((string= operator "&") 30)
   ((string= operator "^") 20)
   ((string= operator "|") 10)
   (t nil)))

(defun constra-generator--parse-expression
    (tokens defines)
  "Evaluate TOKENS as a C integer expression using DEFINES.

Return an integer or nil."
  (let ((pos 0))

    (cl-labels
        ((peek ()
           (nth pos tokens))

         (consume ()
           (prog1
               (nth pos tokens)
             (setq pos (1+ pos))))

         (primary ()
           (let ((token (peek)))
             (cond
              ((null token)
               nil)

              ((string= token "(")
               (consume)
               (let ((value (expr 0)))
                 (when (and value
                            (string= (peek) ")"))
                   (consume)
                   value)))

              ((string-match-p
                "\\`[A-Za-z_]"
                token)
               (consume)
               (constra-generator--value
                token
                defines))

              (t
               (consume)
               (constra-generator--parse-number token)))))

         (unary ()
           (let ((token (peek)))
             (cond
              ((member token '("+" "-" "~"))
               (consume)
               (let ((value (unary)))
                 (when (numberp value)
                   (cond
                    ((string= token "+") value)
                    ((string= token "-") (- value))
                    ((string= token "~") (lognot value))))))

              (t
               (primary)))))

         (expr (min-precedence)
           (let ((left (unary)))
             (while
                 (and left
                      (let ((prec
                             (constra-generator--binary-precedence
                              (peek))))
                        (and prec
                             (>= prec min-precedence))))
               (let* ((operator (consume))
                      (prec
                       (constra-generator--binary-precedence
                        operator))
                      (right
                       (expr (1+ prec))))
                 (setq left
                       (when (numberp right)
                         (condition-case nil
                             (cond
                              ((string= operator "*")
                               (* left right))

                              ((string= operator "/")
                               (if (zerop right)
                                   nil
                                 (/ left right)))

                              ((string= operator "%")
                               (if (zerop right)
                                   nil
                                 (% left right)))

                              ((string= operator "+")
                               (+ left right))

                              ((string= operator "-")
                               (- left right))

                              ((string= operator "<<")
                               (ash left right))

                              ((string= operator ">>")
                               (ash left (- right)))

                              ((string= operator "&")
                               (logand left right))

                              ((string= operator "^")
                               (logxor left right))

                              ((string= operator "|")
                               (logior left right))

                              (t nil))
                           (error nil))))))
             left)))

      (let ((value (expr 0)))
        (when (and (numberp value)
                   (= pos (length tokens)))
          value)))))

(defun constra-generator--value (name defines &optional seen)
  "Return numeric value of macro NAME from DEFINES.

SEEN prevents recursive macro definitions from looping forever."
  (unless (member name seen)
    (let ((entry (assoc name defines)))
      (when entry
        (let* ((value (string-trim (cdr entry)))
               (number (constra-generator--parse-number value)))
          (or
           number
           (let ((tokens
                  (constra-generator--tokenize-expression value)))
             (when tokens
               (constra-generator--evaluate-expression-with-seen
                tokens
                defines
                (cons name seen))))))))))

(defun constra-generator--evaluate-expression-with-seen
    (tokens defines seen)
  "Evaluate TOKENS using DEFINES while tracking SEEN macros."
  (let ((pos 0))

    (cl-labels
        ((peek ()
           (nth pos tokens))

         (consume ()
           (prog1
               (nth pos tokens)
             (setq pos (1+ pos))))

         (primary ()
           (let ((token (peek)))
             (cond
              ((null token)
               nil)

              ((string= token "(")
               (consume)
               (let ((value (expr 0)))
                 (when (and value
                            (string= (peek) ")"))
                   (consume)
                   value)))

              ((string-match-p
                "\\`[A-Za-z_]"
                token)
               (consume)
               (constra-generator--value
                token
                defines
                seen))

              (t
               (consume)
               (constra-generator--parse-number token)))))

         (unary ()
           (let ((token (peek)))
             (if (member token '("+" "-" "~"))
                 (progn
                   (consume)
                   (let ((value (unary)))
                     (when (numberp value)
                       (cond
                        ((string= token "+") value)
                        ((string= token "-") (- value))
                        ((string= token "~") (lognot value))))))
               (primary))))

         (expr (min-precedence)
           (let ((left (unary)))
             (while
                 (and left
                      (let ((prec
                             (constra-generator--binary-precedence
                              (peek))))
                        (and prec
                             (>= prec min-precedence))))
               (let* ((operator (consume))
                      (prec
                       (constra-generator--binary-precedence
                        operator))
                      (right
                       (expr (1+ prec))))
                 (setq left
                       (when (numberp right)
                         (condition-case nil
                             (cond
                              ((string= operator "*")
                               (* left right))
                              ((string= operator "/")
                               (unless (zerop right)
                                 (/ left right)))
                              ((string= operator "%")
                               (unless (zerop right)
                                 (% left right)))
                              ((string= operator "+")
                               (+ left right))
                              ((string= operator "-")
                               (- left right))
                              ((string= operator "<<")
                               (ash left right))
                              ((string= operator ">>")
                               (ash left (- right)))
                              ((string= operator "&")
                               (logand left right))
                              ((string= operator "^")
                               (logxor left right))
                              ((string= operator "|")
                               (logior left right))
                              (t nil))
                           (error nil))))))

             left)))

      (let ((value (expr 0)))
        (when (and (numberp value)
                   (= pos (length tokens)))
          value)))))

(defun constra-generator--evaluate (defines)
  "Evaluate numeric DEFINES."
  (let (result)
    (dolist (entry defines)
      (let ((value
             (constra-generator--value
              (car entry)
              defines)))
        (when (numberp value)
          (push
           (cons (car entry) value)
           result))))
    (nreverse result)))

(defun constra-generator--generate-group
    (context group defines)
  "Generate GROUP."
  (let* ((selected
          (constra-generator--select
           defines
           (plist-get group :prefixes)
           (plist-get group :include)))

         (values
          (constra-generator--evaluate selected)))

    (message
     "Constra: %s/%s: %d constants"
     (plist-get context :context)
     (plist-get group :name)
     (length values))

    (list
     :name (plist-get group :name)
     :type (plist-get group :type)
     :flags values)))

(defun constra-generator--generate-context (context)
  "Generate CONTEXT."
  (let* ((headers
          (plist-get context :headers))

         (defines
          (constra-generator--collect-defines headers))

         (groups
          (mapcar
           (lambda (group)
             (constra-generator--generate-group
              context
              group
              defines))
           (plist-get context :groups))))

    (list
     :context (plist-get context :context)
     :description (plist-get context :description)
     :headers headers
     :groups groups)))

(defun constra-generator--write-context (context)
  "Write CONTEXT to the current buffer."
  (insert
   "(constra-db-register\n"
   " '(:context "
   (prin1-to-string
    (plist-get context :context))
   "\n :description "
   (prin1-to-string
    (plist-get context :description))
   "\n :headers "
   (prin1-to-string
    (plist-get context :headers))
   "\n :groups "
   (prin1-to-string
    (plist-get context :groups))
   "))\n\n"))

(defun constra-generator-write (output-file contexts)
  "Write CONTEXTS to OUTPUT-FILE."
  (make-directory
   (file-name-directory output-file)
   t)

  (with-temp-file output-file
    (insert
     ";;; linux-generated.el\n"
     ";;; Automatically generated by Constra.\n"
     ";;; Do not edit manually.\n\n"
     "(require 'constra-db)\n\n")

    (dolist (context contexts)
      (constra-generator--write-context
       (constra-generator--generate-context context)))

    (insert
     "(provide 'linux-generated)\n"))

  (message
   "Constra: generated %d contexts into %s"
   (length contexts)
   output-file))

(defun constra-generator-load-providers ()
  "Load all Linux generator providers."
  (dolist
      (file
       '("linux-memory"
         "linux-files"
         "linux-sockets"
         "linux-process"
         "linux-signals"
         "linux-epoll"
         "linux-poll"
         "linux-filesystem"
         "linux-futex"
         "linux-time"
         "linux-ipc"
         "linux-security"))
    (require (intern file))))

;;;###autoload
(defun constra-generate ()
  "Generate the Linux Constra database."
  (interactive)

  (setq constra-generator-contexts nil)

  (constra-generator-load-providers)

  (constra-generator-write
   (expand-file-name
    "linux-generated.el"
    constra-generator-output-directory)
   (reverse constra-generator-contexts)))

(provide 'constra-generator)

;;; constra-generator.el ends here
