;;; linux-time.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "clock_gettime/clock"
   :description "Clock identifier"
   :headers ("time.h")
   :groups
   ((:name "clock"
     :type enum
     :include ("CLOCK_REALTIME"
               "CLOCK_MONOTONIC"
               "CLOCK_PROCESS_CPUTIME_ID"
               "CLOCK_THREAD_CPUTIME_ID"
               "CLOCK_MONOTONIC_RAW"
               "CLOCK_REALTIME_COARSE"
               "CLOCK_MONOTONIC_COARSE"
               "CLOCK_BOOTTIME"
               "CLOCK_REALTIME_ALARM"
               "CLOCK_BOOTTIME_ALARM")))))

(constra-generator-register-context
 '(:context "timerfd_create/clock"
   :description "timerfd clock identifier"
   :headers ("sys/timerfd.h"
             "time.h")
   :groups
   ((:name "clock"
     :type enum
     :prefixes ("CLOCK_")))))

(constra-generator-register-context
 '(:context "timerfd_create/flags"
   :description "timerfd flags"
   :headers ("sys/timerfd.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("TFD_")))))

(provide 'linux-time)

;;; linux-time.el ends here
