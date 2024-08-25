;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

;; Disable magit-todos to not overload CPU with binary blobs.
((magit-status-mode . ((magit-todos-exclude-globs . ("*")))))
