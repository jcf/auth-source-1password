
;;; auth-source-1password.el --- 1password integration for auth-source -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Dominick LoBraico
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: Dominick LoBraico <auth-source-1password@lobrai.co>
;;         James Conroy-Finn <james@invetica.co.uk>
;; Created: 2023-04-09
;; URL: https://github.com/dlobraico

;; Package-Requires: ((emacs "24.4"))

;; Version: 0.0.1

;;; Commentary:
;; This package adds 1password support to auth-source by calling the op CLI.
;; Heavily inspired by the auth-source-gopass package
;; (https://github.com/triplem/auth-source-gopass)

;;; Code:
(require 'auth-source)

(defgroup auth-source-1password nil
  "A 1Password backend for auth-source."
  :group 'auth-source
  :tag "auth-source-1password"
  :prefix "1password-")

(defcustom auth-source-1password-account ""
  "Optional 1Password account to use when searching for secrets."
  :type 'string
  :group 'auth-source-1password)

(defcustom auth-source-1password-vault "Personal"
  "1Password vault to use when searching for secrets."
  :type 'string
  :group 'auth-source-1password)

(defcustom auth-source-1password-executable "op"
  "Executable used by auth-source-1password to read secrets."
  :type 'string
  :group 'auth-source-1password)

(defcustom auth-source-1password-construct-secret-reference 'auth-source-1password--make-secret-reference
  "Function to construct the query path in the 1password store."
  :type 'function
  :group 'auth-source-1password)

(defun auth-source-1password--make-secret-reference (_backend _type host user _port)
  "Construct the full entry-path for the 1password entry for HOST and USER.
Usually starting with the `auth-source-1password-vault', followed
by host and user."
  (mapconcat #'identity (list auth-source-1password-vault host user) "/"))

(defun auth-source-1password--op-read (executable account secret-reference)
  (format "%s read %s op://%s"
          executable
          (when (not (string-equal "" account)) (concat "--account " account))
          secret-reference))

(cl-defun auth-source-1password-search (&rest spec
                                              &key backend type host user port
                                              &allow-other-keys)
  "Search 1password for the specified user and host.
SPEC, BACKEND, TYPE, HOST, USER and PORT are required by auth-source."
  (if (not (executable-find auth-source-1password-executable))
      (warn "`auth-source-1password': Could not find executable '%s'."
            auth-source-1password-executable)
    (let* ((secret-reference (shell-quote-argument
                              (funcall auth-source-1password-construct-secret-reference backend type host user port)))
           (shell-command (auth-source-1password--op-read
                           auth-source-1password-executable
                           auth-source-1password-account
                           secret-reference)))
      (message "`auth-source-1password': %s" shell-command)
      (list
       (list :user user
             :secret (string-trim (shell-command-to-string shell-command)))))))

;;;###autoload
(defun auth-source-1password-enable ()
  "Enable the 1password auth source."
  (add-to-list 'auth-sources '1password)
  (auth-source-forget-all-cached))

(defvar auth-source-1password-backend
  (auth-source-backend
   :source "."
   :type 'password-store
   :search-function #'auth-source-1password-search))

(defun auth-source-1password-backend-parse (entry)
  "Create a 1password auth-source backend from ENTRY."
  (when (eq entry '1password)
    (auth-source-backend-parse-parameters entry auth-source-1password-backend)))

(if (boundp 'auth-source-backend-parser-functions)
    (add-hook 'auth-source-backend-parser-functions #'auth-source-1password-backend-parse)
  (advice-add 'auth-source-backend-parse :before-until #'auth-source-1password-backend-parse))

(provide 'auth-source-1password)
;;; auth-source-1password.el ends here
