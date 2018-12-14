;;; venv.el --- simple virtualenv support for Emacs.

;; Author: Daniel Kertesz (but James J. Porter really)
;; Version: 1.0
;; Keywords: python, virtualenv
;; URL: https://github.com/piger/venv.el
;; Package-Requires: ((dash "1.5.0") (s "1.6.1"))

;;; Commentary:

;; Enough to get pylint/pep8 to work with flycheck.  I don't like virtualenvwrapper.  It used to slow
;; down the startup time for my shell in the pre-SSD era, and just to save from typing
;; "source ~/tmp/venvs/$project_name"? No thanks.
;; Code copied from: https://github.com/porterjamesj/virtualenvwrapper.el

;;; Code:

(require 'dash)
(require 's)


(defgroup venv nil
  "Virtualenv support for Emacs."
  :group 'python)

(defvar venv-current-name nil "Name of current virtualenv.")

(defvar venv-current-dir nil "Directory of current virtualenv.")

(defvar venv-executables-dir
  (if (eq system-type 'windows-nt) "Scripts" "bin")
  "The name of the directory containing executables.  It is system dependent.")

(defvar venv-preactivate-hook nil
  "Hook run before a virtualenv is activated.")

(defvar venv-postactivate-hook nil
  "Hook run after a virtualenv is activated.")

(defvar venv-predeactivate-hook nil
  "Hook run before a virtualenv is deactivated.")

(defvar venv-postdeactivate-hook nil
  "Hook run after a virtualenv is deactivated.")



(defun venv-get-stripped-path (path)
  "Strip the virtualenv path from PATH.
Return what the PATH would look like if we weren't in a
virtualenv.  PATH should be a list of strings specifiying directories."
  (if (not venv-current-dir)
      path
    (-filter
     (lambda (s) (not (s-equals? s (concat venv-current-dir venv-executables-dir))))
     path)))

(defun venv--activate-dir (dir)
  "Given a directory DIR corresponding to a virtualenv, activate it."
  (run-hooks 'venv-preactivate-hook)
  (setq venv-current-dir dir)
  ;; setup the python shell
  (setq python-shell-virtualenv-path venv-current-dir)
  ;; setup emacs exec-path
  (add-to-list 'exec-path (concat venv-current-dir venv-executables-dir))
  ;; setup the environment for subprocesses
  (setenv "PATH" (concat venv-current-dir venv-executables-dir path-separator (getenv "PATH")))
  ;; keep eshell path in sync
  (setq eshell-path-env (getenv "PATH"))
  (setenv "VIRTUAL_ENV" venv-current-dir)
  (run-hooks 'venv-postactivate-hook))

;;;###autoload
(defun venv-from-poetry ()
  "Get the virtualenv path from poetry."
  (interactive)
  (venv--activate-dir (replace-regexp-in-string "\n$" ""
                                                (shell-command-to-string "poetry debug:info | awk '/Path/ { print $3 \"/\" }'"))))

;;;###autoload
(defun venv-activate (&optional location)
  "Interactively switch to virtualenv LOCATION.
Prompts for name if called interactively."
  (interactive)
  (when (not location)
    (setq location (read-directory-name "Virtualenv path: ")))
  ;; deactivate first
  (venv-deactivate)
  ;; then switch
  (setq venv-current-name location) ;; XXX should be a name
  ;; actually activate it
  (venv--activate-dir location)
  (when (called-interactively-p 'interactive)
    (message (concat "Switched to virtualenv: " venv-current-name))))

;;;###autoload
(defun venv-deactivate ()
  "Deactivate the current virtualenv."
  (interactive)
  (when venv-current-dir
    (run-hooks 'venv-predeactivate-hook)
    (setq python-shell-virtualenv-path nil)
    (setq exec-path (venv-get-stripped-path exec-path))
    (setenv "PATH" (s-join path-separator
                           (venv-get-stripped-path
                            (s-split path-separator (getenv "PATH")))))
    (setenv "VIRTUAL_ENV" nil)
    (setq venv-current-name nil)
    (setq venv-current-dir nil)
    (setq eshell-path-env (getenv "PATH"))
    (run-hooks 'venv-postdeactivate-hook))
  (when (called-interactively-p 'interactive)
    (message "virtualenv deactivated")))

(provide 'venv)
;;; venv.el ends here
