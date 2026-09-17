;;; linux-memory.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "mprotect/prot"
   :description "Memory protection"
   :headers ("sys/mman.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("PROT_")))))

(constra-generator-register-context
 '(:context "mmap/prot"
   :description "Memory mapping protection"
   :headers ("sys/mman.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("PROT_")))))

(constra-generator-register-context
 '(:context "mmap/flags"
   :description "Memory mapping flags"
   :headers ("sys/mman.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MAP_")))))

(constra-generator-register-context
 '(:context "madvise/advice"
   :description "Memory advice"
   :headers ("sys/mman.h")
   :groups
   ((:name "advice"
     :type enum
     :prefixes ("MADV_")))))

(constra-generator-register-context
 '(:context "msync/flags"
   :description "Memory synchronization flags"
   :headers ("sys/mman.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MS_")))))

(constra-generator-register-context
 '(:context "mlock2/flags"
   :description "Memory locking flags"
   :headers ("sys/mman.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MLOCK_")))))

(provide 'linux-memory)

;;; linux-memory.el ends here
