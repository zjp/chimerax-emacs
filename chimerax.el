;;; chimerax.el --- ChimeraX command line REPL -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Ivan Yonchovski
;; Copyright (C) 2024 Zach Pearson

;; Author: Zach Pearson <z.pearson9@gmail.com>
;; URL: https://github.com/zjp/chimerax-emacs
;; Version: 0.1
;; Package-Requires: ((emacs "25.1"))

;; The original authors of dap-ui.el at the time of writing have been included
;; here so that proper credit is attributed. Please do not bother them if you
;; find bugs.

;; This program is free software; you can redistribute it and/or modify
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
;; REPL that can serve as an alternative to ChimeraX's command line

;;; Code:
(require 'request)

(provide 'chimerax)

(defconst chimerax--repl-buffer "*chimerax*")

(defgroup chimerax nil
  "'chimerax.el' allows you to interact with ChimeraX from Emacs"
  :group 'convenience)

(defcustom chimerax-repl-prompt ">> "
  "Prompt string for ChimeraX command line."
  :type 'string
  :group 'chimerax)

(defcustom chimerax-rest-url "http://localhost:3000"
  "Set this to the URL from running `remotecontrol rest start` in ChimeraX.
   You should configure ChimeraX so that it starts the server automatically,
   uses the same port every time, and uses json:
   `remotecontrol rest start port xxxx json true`"
  :type 'string
  :group 'chimerax)

(defcustom chimerax-repl-history-dir user-emacs-directory
  "Directory path for ChimeraX command input history files."
  :type 'directory
  :group 'chimerax)

(defun chimerax-send-command (command)
  (request (string-join `(,chimerax-rest-url "/" "run"))
    :type "POST"
    :params `(("command" . ,command))
    :parser 'json-read
    :success (cl-function
              (lambda (&key data &allow-other-keys)
                (comint-output-filter (chimerax-repl-process)
                                      (concat "log notes: \n"
                                              (chimerax--get-logged-messages data)
                                              "log warnings: \n"
                                              (chimerax--get-logged-warnings data)
                                              "log errors: \n"
                                              (chimerax--get-logged-errors data)
                                              "log bugs: \n"
                                              (chimerax--get-logged-bugs data)
                                              ;; TOOD:
                                              ;; "errors: \n"
                                              ;; (chimerax--get-error-message data)
                                              ;; "\n"
                                              ;;"json values: "
                                              ;;(chimerax--get-json-values data)
                                              ;;"\n"
                                              ;;(chimerax--get-python-values data)
                                              ;;"\n"
                                              chimerax-repl-prompt))))))

(defun chimerax--get-logged-item (position data)
  (if (> (length (cdr (nth position (cdr (nth 2 data))))) 0)
      ;; strip the final newline
      (substring (aref (cdr (nth position (cdr (nth 2 data)))) 0) 0 -1)
    ""))

(defun chimerax--get-logged-messages (data)
  (chimerax--get-logged-item 0 data))

(defun chimerax--get-logged-warnings (data)
  (chimerax--get-logged-item 1 data))

(defun chimerax--get-logged-errors (data)
  (chimerax--get-logged-item 2 data))

(defun chimerax--get-logged-bugs (data)
  (chimerax--get-logged-item 3 data))

(defun chimerax--get-error-message (data)
  (if (> (length (nth 3 data)) 0)
      (let ((error-type (cdr (nth 0 (cdr (nth 3 data)))))
            (error-message (cdr (nth 1 (cdr (nth 3 data))))))
        (format "%s: %s" error-type error-message))
    ""))

;; adapted from dap-ui's REPL code
(defun chimerax-repl ()
  "Start a ChimeraX command line REPL."
  (interactive)
  (let ((repl-buf (get-buffer chimerax--repl-buffer)))
    (unless repl-buf
      (with-current-buffer (get-buffer-create chimerax--repl-buffer)
        (chimerax-repl-mode)
        (when (functionp 'company-mode)
          (company-mode 1))
        (setq repl-buf (current-buffer))))
    (chimerax--show-buffer repl-buf)))

(defun chimerax--show-buffer (buf)
  "Show BUF according to defined rules."
  (when-let (win (display-buffer-in-side-window buf
                                                '((side . bottom)
                                                  (slot . 0))))
    (set-window-dedicated-p win t)
    (select-window win)))

(defun chimerax-input-sender (_ input)
  "REPL comint handler.
INPUT is the current input."
  (chimerax-send-command input)
  (comint-write-input-ring))

(define-derived-mode chimerax-repl-mode comint-mode "CHIMERAX-REPL"
  "Provide a REPL for the active debug session."
  :group 'chimerax
  :syntax-table emacs-lisp-mode-syntax-table
  (setq comint-prompt-regexp (concat "^" (regexp-quote chimerax-repl-prompt))
        comint-input-sender 'chimerax-input-sender
        comint-process-echoes nil)
  ;; TODO Company mode
  ;;(with-no-warnings
  ;;  (setq-local company-backends '(chimerax-repl-company)))
  (unless (comint-check-proc (current-buffer))
    (setq comint-input-ring-file-name
          (f-join chimerax-repl-history-dir
                  ;; concat unique history file for each dap type
                  (concat
                   "chimerax-repl-"
                   ;; :type is required so this should always exist
                   (format-time-string "%Y-%m-%d")
                   "-history")))
    (insert chimerax-repl-welcome)
    (start-process "chimerax-repl" (current-buffer) nil)
    (set-process-query-on-exit-flag (chimerax-repl-process) nil)
    (goto-char (point-max))
    (set (make-local-variable 'comint-inhibit-carriage-motion) t)
    (comint-output-filter (chimerax-repl-process) chimerax-repl-prompt)
    (set-process-filter (chimerax-repl-process) 'comint-output-filter)
    (comint-read-input-ring 'silent)))

(defun chimerax-repl-process ()
  "Return the process for the chimerax REPL."
  (get-buffer-process (current-buffer)))

(defvar chimerax-repl-welcome
  (propertize "*** Welcome to ChimeraX ***\n"
              'font-lock-face 'font-lock-comment-face)
  "Header line to show at the top of the REPL buffer.
Hack notice: this allows log messages to appear before anything is
evaluated because it provides insertable space at the top of the
buffer.")

;;; chimerax.el ends here
