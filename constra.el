;;; constra.el --- Reverse-engineering constants for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Your Name
;;
;; Author: Giovanni Francesco Iannaccone <iannacconegiovanni444@gmail.com>
;; Maintainer: Giovanni Francesco Iannaccone <iannacconegiovanni444@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools, reverse-engineering, debugging, systems
;; URL: https://github.com/giovanni-iannaccone/constra
;;
;; This file is part of Constra.
;;
;; Constra is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; Constra is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Constra. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Constra provides an Emacs interface for looking up and composing
;; numeric constants commonly encountered during reverse engineering
;; and low-level debugging.
;;
;; Interactive commands:
;;
;; M-x constra-lookup
;;     Look up a numeric constant in a selected context.
;;
;; M-x constra-compose
;;     Compose multiple constants into a numeric value.
;;
;; M-x constra-describe-context
;;     Describe the groups available in a context.
;;
;;; Code:

(defconst constra-dir
  (file-name-directory
   (or load-file-name buffer-file-name)))

(add-to-list 'load-path constra-dir)
(add-to-list 'load-path
             (expand-file-name "data" constra-dir))
(add-to-list 'load-path
             (expand-file-name "data/generated" constra-dir))

(autoload 'constra-lookup
  "constra-ui"
  "Decode a numeric constant in a selected context."
  t)

(autoload 'constra-compose
  "constra-ui"
  "Compose multiple constants into a numeric value."
  t)

(autoload 'constra-describe-context
  "constra-ui"
  "Display all groups belonging to a context."
  t)

(autoload 'constra-generate
  "constra-generator"
  "Generate Constra data."
  t)

(provide 'constra)

;;; constra.el ends here
