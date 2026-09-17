;;; linux-sockets.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "socket/domain"
   :description "Socket address family"
   :headers ("sys/socket.h")
   :groups
   ((:name "domain"
     :type enum
     :prefixes ("AF_")))))

(constra-generator-register-context
 '(:context "socket/type"
   :description "Socket type and modifiers"
   :headers ("sys/socket.h")
   :groups
   ((:name "type"
     :type composite
     :include ("SOCK_STREAM"
               "SOCK_DGRAM"
               "SOCK_RAW"
               "SOCK_RDM"
               "SOCK_SEQPACKET"
               "SOCK_NONBLOCK"
               "SOCK_CLOEXEC")))))

(constra-generator-register-context
 '(:context "socket/protocol"
   :description "Socket protocol"
   :headers ("sys/socket.h")
   :groups
   ((:name "protocol"
     :type enum
     :prefixes ("IPPROTO_")))))

(constra-generator-register-context
 '(:context "send/flags"
   :description "send flags"
   :headers ("sys/socket.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MSG_")))))

(constra-generator-register-context
 '(:context "recv/flags"
   :description "recv flags"
   :headers ("sys/socket.h")
   :groups
   ((:name "flags"
     :type bitmask
     :prefixes ("MSG_")))))

(constra-generator-register-context
 '(:context "shutdown/how"
   :description "Socket shutdown mode"
   :headers ("sys/socket.h")
   :groups
   ((:name "how"
     :type enum
     :include ("SHUT_RD"
               "SHUT_WR"
               "SHUT_RDWR")))))

(provide 'linux-sockets)

;;; linux-sockets.el ends here
