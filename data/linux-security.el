;;; linux-security.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "seccomp/operation"
   :description "seccomp operation"
   :headers ("linux/seccomp.h")
   :groups
   ((:name "operation"
     :type enum
     :include ("SECCOMP_SET_MODE_STRICT"
               "SECCOMP_SET_MODE_FILTER"
               "SECCOMP_GET_ACTION_AVAIL"
               "SECCOMP_GET_NOTIF_SIZES")))))

(constra-generator-register-context
 '(:context "seccomp/flags"
   :description "seccomp flags"
   :headers ("linux/seccomp.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("SECCOMP_FILTER_FLAG_")))))

(provide 'linux-security)

;;; linux-security.el ends here
