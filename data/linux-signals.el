;;; linux-signals.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "sigaction/flags"
   :description "Signal action flags"
   :headers ("signal.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("SA_")))))

(constra-generator-register-context
 '(:context "sigprocmask/how"
   :description "Signal mask operation"
   :headers ("signal.h")
   :groups
   ((:name "how"
     :type enum
     :include ("SIG_BLOCK"
               "SIG_UNBLOCK"
               "SIG_SETMASK")))))

(constra-generator-register-context
 '(:context "signalfd/flags"
   :description "signalfd flags"
   :headers ("sys/signalfd.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("SFD_")))))

(provide 'linux-signals)

;;; linux-signals.el ends here
