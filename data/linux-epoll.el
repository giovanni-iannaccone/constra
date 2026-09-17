;;; linux-epoll.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "epoll_create1/flags"
   :description "epoll_create1 flags"
   :headers ("sys/epoll.h")
   :groups
   ((:name "flags"
     :type bitmask
     :include ("EPOLL_CLOEXEC")))))

(constra-generator-register-context
 '(:context "epoll_ctl/op"
   :description "epoll control operation"
   :headers ("sys/epoll.h")
   :groups
   ((:name "operation"
     :type enum
     :include ("EPOLL_CTL_ADD"
               "EPOLL_CTL_DEL"
               "EPOLL_CTL_MOD")))))

(constra-generator-register-context
 '(:context "epoll_event/events"
   :description "epoll event flags"
   :headers ("sys/epoll.h")
   :groups
   ((:name "events"
     :type bitmask
     :include ("EPOLLIN"
               "EPOLLPRI"
               "EPOLLOUT"
               "EPOLLRDNORM"
               "EPOLLRDBAND"
               "EPOLLWRNORM"
               "EPOLLWRBAND"
               "EPOLLMSG"
               "EPOLLERR"
               "EPOLLHUP"
               "EPOLLRDHUP"
               "EPOLLET"
               "EPOLLONESHOT"
               "EPOLLWAKEUP")))))

(provide 'linux-epoll)

;;; linux-epoll.el ends here
