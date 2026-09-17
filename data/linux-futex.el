;;; linux-futex.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "futex/op"
   :description "futex operation"
   :headers ("linux/futex.h")
   :groups
   ((:name "operation"
     :type composite
     :include ("FUTEX_WAIT"
               "FUTEX_WAKE"
               "FUTEX_FD"
               "FUTEX_REQUEUE"
               "FUTEX_CMP_REQUEUE"
               "FUTEX_WAKE_OP"
               "FUTEX_LOCK_PI"
               "FUTEX_UNLOCK_PI"
               "FUTEX_TRYLOCK_PI"
               "FUTEX_WAIT_BITSET"
               "FUTEX_WAKE_BITSET"
               "FUTEX_WAIT_REQUEUE_PI"
               "FUTEX_CMP_REQUEUE_PI"
               "FUTEX_PRIVATE_FLAG"
               "FUTEX_CLOCK_REALTIME")))))

(provide 'linux-futex)

;;; linux-futex.el ends here
