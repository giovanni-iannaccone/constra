;;; linux-filesystem.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "mount/flags"
   :description "mount flags"
   :headers ("sys/mount.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MS_")))))

(constra-generator-register-context
 '(:context "statx/mask"
   :description "statx result mask"
   :headers ("linux/stat.h")
   :groups
   ((:name "mask"
     :type bitmask
     :prefixes ("STATX_")))))

(constra-generator-register-context
 '(:context "statx/flags"
   :description "statx flags"
   :headers ("linux/stat.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("AT_")))))

(provide 'linux-filesystem)

;;; linux-filesystem.el ends here
