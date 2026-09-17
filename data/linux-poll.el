;;; linux-poll.el -*- lexical-binding: t; -*-

(require 'constra-generator)

(constra-generator-register-context
 '(:context "poll/events"
   :description "poll event flags"
   :headers ("poll.h")
   :groups
   ((:name "events"
     :type bitmask
     :include ("POLLIN"
               "POLLPRI"
               "POLLOUT"
               "POLLRDHUP"
               "POLLERR"
               "POLLHUP"
               "POLLNVAL")))))

(provide 'linux-poll)

;;; linux-poll.el ends here
