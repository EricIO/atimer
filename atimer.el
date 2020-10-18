;;; atimer.el --- A timer for emacs

;; Copyright (C) 2020 Eric Skoglund <eric@pagefault.se>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; atimer is a little library that will provide you with
;; the functionality of setting timers and stopping timers..
;;
;; It will also tell you when the timer has ended.  That's pretty
;; much what you would expect right?


;;; Code:

(defvar atimer--timers-alist nil
  "Current active timers.")

(defvar atimer--timer-notify-function 'atimer-notify-with-notification
  "The function that atimer will use to alert the user.")

(defvar atimer--notification-timeout 15
  "The number of seconds that the notification will be shown.")

(defun atimer-notify-with-notification (msg)
  "Use the notifications library to show the MSG notification.
Fallback to message if it is not found."
  (if (require 'notifications nil 'no-error)
      (cond
       ((fboundp 'w32-notification-notify)
        (let ((notification (w32-notification-notify
                             :title "atimer notification"
                             :body msg
                             :urgency 'low)))
          (run-with-timer atimer--notification-timeout
                          nil
                          (lambda () (w32-notification-close notification)))))
       ((fboundp 'notifications-notify)
        (notifications-notify
         :title "atimer notification"
         :body msg
         :timeout atimer--notification-timeout
         :urgency 'low)))
    (message "%s" msg)))

(defun atimer-notify (message)
  "Notify the user that a timer has ended with the provided MESSAGE.
Uses the function set in `atimer--timer-notify-function'."
  (funcall atimer--timer-notify-function message)
  (setq atimer--timers-alist
        (assq-delete-all message atimer--timers-alist)))

(defun atimer-clear-timers ()
  "Clears all running timers."
  (interactive)
  (if (yes-or-no-p "Remove all running timers?")
      (progn
        (dolist (timer atimer--timers-alist)
          (cancel-timer (cdr timer)))
        (setq atimer--timers-alist nil))))

(defun atimer-new-timer ()
  "Start a new timer."
  (interactive)
  (let ((msg (read-string "Timer message: "))
        (time (read-string "Time: ")))
    (push `(,msg . ,(run-at-time time nil 'atimer-notify msg))
          atimer--timers-alist)))

(provide 'atimer)
;;; atimer.el ends here
