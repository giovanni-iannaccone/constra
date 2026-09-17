;;; linux-files.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "open/access-mode"
   :description "File access mode"
   :headers ("fcntl.h")
   :groups
   ((:name "access-mode"
     :type enum
     :include ("O_RDONLY"
               "O_WRONLY"
               "O_RDWR")))))

(constra-generator-register-context
 '(:context "open/flags"
   :description "File open flags"
   :headers ("fcntl.h")
   :groups
   ((:name "flags"
     :type bitmask
     :include ("O_APPEND"
               "O_ASYNC"
               "O_CLOEXEC"
               "O_CREAT"
               "O_DIRECT"
               "O_DIRECTORY"
               "O_DSYNC"
               "O_EXCL"
               "O_NOATIME"
               "O_NOCTTY"
               "O_NOFOLLOW"
               "O_NONBLOCK"
               "O_PATH"
               "O_SYNC"
               "O_TMPFILE"
               "O_TRUNC"
               "O_LARGEFILE")))))

(constra-generator-register-context
 '(:context "fcntl/cmd"
   :description "fcntl command"
   :headers ("fcntl.h")
   :groups
   ((:name "command"
     :type enum
     :prefixes ("F_")))))

(constra-generator-register-context
 '(:context "lseek/whence"
   :description "File seek mode"
   :headers ("unistd.h"
             "stdio.h")
   :groups
   ((:name "whence"
     :type enum
     :include ("SEEK_SET"
               "SEEK_CUR"
               "SEEK_END"
               "SEEK_DATA"
               "SEEK_HOLE")))))

(provide 'linux-files)

;;; linux-files.el ends here
