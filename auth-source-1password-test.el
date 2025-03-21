(let ((root (file-name-directory (or load-file-name buffer-file-name))))
  (load (expand-file-name "auth-source-1password.el" root)))

(require 'ert)

(ert-deftest auth-source-1password--op-read ()
  "Concatenation of configuration."
  (let ((executable "op")
        (account ""))
    (should (string-equal
             "op read op://secret"
             (auth-source-1password--op-read executable account "secret"))))
  (let ((executable "op")
        (account "example.1password.eu"))
    (should (string-equal
             "op read --account example.1password.eu op://secret"
             (auth-source-1password--op-read executable account "secret")))))
