;;; linux-process.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "clone/flags"
   :description "Process and namespace clone flags"
   :headers ("sched.h"
             "linux/sched.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("CLONE_")))))

(constra-generator-register-context
 '(:context "clone3/flags"
   :description "clone3 flags"
   :headers ("linux/sched.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("CLONE_")))))

(constra-generator-register-context
 '(:context "unshare/flags"
   :description "Namespace unshare flags"
   :headers ("sched.h"
             "linux/sched.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("CLONE_")))))

(constra-generator-register-context
 '(:context "setns/flags"
   :description "Namespace setns flags"
   :headers ("sched.h"
             "linux/sched.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("CLONE_")))))

(constra-generator-register-context
 '(:context "prctl/option"
   :description "prctl operation"
   :headers ("sys/prctl.h"
             "linux/prctl.h")
   :groups
   ((:name "option"
     :type enum
     :prefixes ("PR_")))))

(provide 'linux-process)

;;; linux-process.el ends here
