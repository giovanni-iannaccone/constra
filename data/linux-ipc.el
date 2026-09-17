;;; linux-ipc.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "shmget/flags"
   :description "System V shared memory flags"
   :headers ("sys/ipc.h"
             "sys/shm.h")
   :groups
   ((:name "flags"
     :type bitmask
     :include ("IPC_CREAT"
               "IPC_EXCL"
               "SHM_HUGETLB"
               "SHM_NORESERVE")))))

(constra-generator-register-context
 '(:context "shmat/flags"
   :description "System V shared memory attach flags"
   :headers ("sys/shm.h")
   :groups
   ((:name "flags"
     :type bitmask
     :include ("SHM_RDONLY"
               "SHM_RND"
               "SHM_REMAP"
               "SHM_EXEC")))))

(constra-generator-register-context
 '(:context "msgget/flags"
   :description "System V message queue flags"
   :headers ("sys/msg.h")
   :groups
   ((:name "flags"
     :type bitmask
     :include ("IPC_CREAT"
               "IPC_EXCL")))))

(constra-generator-register-context
 '(:context "msgctl/command"
   :description "System V message queue command"
   :headers ("sys/msg.h")
   :groups
   ((:name "command"
     :type enum
     :include ("IPC_STAT"
               "IPC_SET"
               "IPC_RMID"
               "IPC_INFO"
               "MSG_STAT"
               "MSG_INFO")))))

(provide 'linux-ipc)

;;; linux-ipc.el ends here
