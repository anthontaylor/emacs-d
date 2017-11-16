;;; init.el --- Prelude's configuration entry point.
;;
;; Copyright (c) 2011-2017 Bozhidar Batsov
;;
;; Author: Bozhidar Batsov <bozhidar@batsov.com>
;; URL: http://batsov.com/prelude
;; Version: 1.0.0
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This file simply sets up the default load path and requires
;; the various modules defined within Emacs Prelude.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;(package-initialize)

(defvar current-user
  (getenv
   (if (equal system-type 'windows-nt) "USERNAME" "USER")))

(message "Prelude is powering up... Be patient, Master %s!" current-user)

(when (version< emacs-version "24.4")
  (error "Prelude requires at least GNU Emacs 24.4, but you're running %s" emacs-version))

(global-linum-mode t)

;; Always load newest byte code
(setq load-prefer-newer t)

(defvar prelude-dir (file-name-directory load-file-name)
  "The root dir of the Emacs Prelude distribution.")
(defvar prelude-core-dir (expand-file-name "core" prelude-dir)
  "The home of Prelude's core functionality.")
(defvar prelude-modules-dir (expand-file-name  "modules" prelude-dir)
  "This directory houses all of the built-in Prelude modules.")
(defvar prelude-personal-dir (expand-file-name "personal" prelude-dir)
  "This directory is for your personal configuration.

Users of Emacs Prelude are encouraged to keep their personal configuration
changes in this directory.  All Emacs Lisp files there are loaded automatically
by Prelude.")
(defvar prelude-personal-preload-dir (expand-file-name "preload" prelude-personal-dir)
  "This directory is for your personal configuration, that you want loaded before Prelude.")
(defvar prelude-vendor-dir (expand-file-name "vendor" prelude-dir)
  "This directory houses packages that are not yet available in ELPA (or MELPA).")
(defvar prelude-savefile-dir (expand-file-name "savefile" prelude-dir)
  "This folder stores all the automatically generated save/history-files.")
(defvar prelude-modules-file (expand-file-name "prelude-modules.el" prelude-dir)
  "This files contains a list of modules that will be loaded by Prelude.")

(unless (file-exists-p prelude-savefile-dir)
  (make-directory prelude-savefile-dir))

(defun prelude-add-subfolders-to-load-path (parent-dir)
 "Add all level PARENT-DIR subdirs to the `load-path'."
 (dolist (f (directory-files parent-dir))
   (let ((name (expand-file-name f parent-dir)))
     (when (and (file-directory-p name)
                (not (string-prefix-p "." f)))
       (add-to-list 'load-path name)
       (prelude-add-subfolders-to-load-path name)))))

;; add Prelude's directories to Emacs's `load-path'
(add-to-list 'load-path prelude-core-dir)
(add-to-list 'load-path prelude-modules-dir)
(add-to-list 'load-path prelude-vendor-dir)
(prelude-add-subfolders-to-load-path prelude-vendor-dir)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;; preload the personal settings from `prelude-personal-preload-dir'
(when (file-exists-p prelude-personal-preload-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-preload-dir)
  (mapc 'load (directory-files prelude-personal-preload-dir 't "^[^#\.].*el$")))

(message "Loading Prelude's core...")

;; the core stuff
(require 'prelude-packages)
(require 'prelude-custom)  ;; Needs to be loaded before core, editor and ui
(require 'prelude-ui)
(require 'prelude-core)
(require 'prelude-mode)
(require 'prelude-editor)
(require 'prelude-global-keybindings)
(require 'prelude-clojure)
(require 'clj-refactor)

;; hideshow setup

(defun hs-clojure-hide-namespace-and-folds ()
  "Hide the first (ns ...) expression in the file, and also all
the (^:fold ...) expressions."
  (interactive)
  (hs-life-goes-on
   (save-excursion
     (goto-char (point-min))
     (when (ignore-errors (re-search-forward "^(ns "))
       (hs-hide-block))

     (while (ignore-errors (re-search-forward "\\^:fold"))
       (hs-hide-block)
       (next-line)))))

(defun hs-clojure-mode-hook ()
  (interactive)
  (hs-minor-mode 1)
  (hs-clojure-hide-namespace-and-folds))

(add-hook 'clojure-mode-hook 'hs-clojure-mode-hook)

;; helm setup

(require 'helm-config)

(setq helm-ff-transformer-show-only-basename nil
      helm-adaptive-history-file "~/.emacs.d/data/helm-history"
      helm-yank-symbol-first t
      helm-move-to-line-cycle-in-source t
      helm-buffers-fuzzy-matching t
      helm-ff-auto-update-initial-value t)

(autoload 'helm-descbinds "helm-descbinds" t)

(autoload 'helm-eshell-history "helm-eshell" t)

(autoload 'helm-esh-pcomplete "helm-eshell" t)

(global-set-key (kbd "C-h a") 'helm-apropos)

(global-set-key (kbd "C-h b") 'helm-descbinds)

;; (add-hook 'eshell-mode-hook
;; #'(lambda ()
;; (define-key eshell-mode-map (kbd "TAB") #'helm-esh-pcomplete)
;; (define-key eshell-mode-map (kbd "C-c C-l") #'helm-eshell-history)))

(add-hook 'eshell-mode-hook
(lambda ()
(define-key eshell-mode-map (kbd "TAB") 'helm-esh-pcomplete)))

(global-set-key (kbd "C-x b") 'helm-mini)

(global-set-key (kbd "C-x C-b") 'helm-buffers-list)

(global-set-key (kbd "C-x C-f") 'helm-find-files)

(global-set-key (kbd "C-x C-r") 'helm-recentf)

(global-set-key (kbd "C-x r l") 'helm-filtered-bookmarks)

(global-set-key (kbd "M-y") 'helm-show-kill-ring)

(global-set-key (kbd "M-s o") 'helm-swoop)

(global-set-key (kbd "M-s /") 'helm-multi-swoop)

(helm-mode t)

;;(helm-adaptative-mode t)

(global-set-key (kbd "C-x c!") 'helm-calcul-expression)

(global-set-key (kbd "C-x c:") 'helm-eval-expression-with-eldoc)

(define-key helm-map (kbd "M-o") 'helm-previous-source)

(global-set-key (kbd "M-s s") 'helm-ag)

;; (require 'helm-projectile)

;; (setq helm-projectile-sources-list (cons 'helm-source-projectile-files-list
;; (remove 'helm-source-projectile-files-list
;; helm-projectile-sources-list)))
;; (helm-projectile-on)

;; (define-key projectile-mode-map (kbd "C-c p /")
;; (lambda ()
;; (interactive)
;; (helm-ag (projectile-project-root))))

;; (define-key org-mode-map (kbd "C-x c o h") #'helm-org-headlines)

(require 'helm-config)

;; (global-set-key (kbd "M-x") 'helm-M-x)

(global-set-key (kbd "C-x b") 'helm-mini)

;; Split frame horizontally and display helm results.
(setq helm-split-window-default-side 'other
helm-split-window-in-side-p t)

(require 'helm-files)

(global-set-key (kbd "C-x C-f") 'helm-find-files)

(setq helm-ff-search-library-in-sexp t)

(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)

(define-key helm-map (kbd "C-i") 'helm-execute-persistent-action)

(define-key helm-map (kbd "C-z") 'helm-select-action)

(require 'helm-grep)

(define-key helm-grep-mode-map (kbd "<return>") 'helm-grep-mode-jump-other-window)

(define-key helm-grep-mode-map (kbd "n") 'helm-grep-mode-jump-other-window-forward)

(define-key helm-grep-mode-map (kbd "p") 'helm-grep-mode-jump-other-window-backward)

;; Caution: This solution might have unintended consequences, such as using grep on the buffers list to recurse on every listed file.
(eval-after-load 'helm-grep
'(setq helm-grep-default-command helm-grep-default-recurse-command))

;; Add current position to mark ring.
(add-hook 'helm-goto-line-before-hook 'helm-save-current-pos-to-mark-ring)

;; TODO: Configure to work with helm-mode while company-mode is also available?
(global-set-key (kbd "C-TAB") 'ac-complete-with-helm)

;;;; fira code setup

(when (window-system)
  (set-default-font "Fira Code"))
(let ((alist '((33 . ".\\(?:\\(?:==\\|!!\\)\\|[!=]\\)")
               (35 . ".\\(?:###\\|##\\|_(\\|[#(?[_{]\\)")
               (36 . ".\\(?:>\\)")
               (37 . ".\\(?:\\(?:%%\\)\\|%\\)")
               (38 . ".\\(?:\\(?:&&\\)\\|&\\)")
               (42 . ".\\(?:\\(?:\\*\\*/\\)\\|\\(?:\\*[*/]\\)\\|[*/>]\\)")
               (43 . ".\\(?:\\(?:\\+\\+\\)\\|[+>]\\)")
               (45 . ".\\(?:\\(?:-[>-]\\|<<\\|>>\\)\\|[<>}~-]\\)")
               ;;(46 . ".\\(?:\\(?:\\.[.<]\\)\\|[.=-]\\)")
               (47 . ".\\(?:\\(?:\\*\\*\\|//\\|==\\)\\|[*/=>]\\)")
               (48 . ".\\(?:x[a-zA-Z]\\)")
               (58 . ".\\(?:::\\|[:=]\\)")
               (59 . ".\\(?:;;\\|;\\)")
               (60 . ".\\(?:\\(?:!--\\)\\|\\(?:~~\\|->\\|\\$>\\|\\*>\\|\\+>\\|--\\|<[<=-]\\|=[<=>]\\||>\\)\\|[*$+~/<=>|-]\\)")
               (61 . ".\\(?:\\(?:/=\\|:=\\|<<\\|=[=>]\\|>>\\)\\|[<=>~]\\)")
               (62 . ".\\(?:\\(?:=>\\|>[=>-]\\)\\|[=>-]\\)")
;;               (63 . ".\\(?:\\(\\?\\?\\)\\|[:=?]\\)")
               (91 . ".\\(?:]\\)")
               (92 . ".\\(?:\\(?:\\\\\\\\\\)\\|\\\\\\)")
               (94 . ".\\(?:=\\)")
               (119 . ".\\(?:ww\\)")
               (123 . ".\\(?:-\\)")
               (124 . ".\\(?:\\(?:|[=|]\\)\\|[=>|]\\)")
               (126 . ".\\(?:~>\\|~~\\|[>=@~-]\\)")
               )
             ))
  (dolist (char-regexp alist)
    (set-char-table-range composition-function-table (car char-regexp)
                          `([,(cdr char-regexp) 0 font-shape-gstring]))))

(add-hook 'helm-major-mode-hook
          (lambda ()
            (setq auto-composition-mode nil)))

;; OSX specific settings
(when (eq system-type 'darwin)
  (require 'prelude-osx))

(message "Loading Prelude's modules...")

;; the modules
(if (file-exists-p prelude-modules-file)
    (load prelude-modules-file)
  (message "Missing modules file %s" prelude-modules-file)
  (message "You can get started by copying the bundled example file"))

;; config changes made through the customize UI will be store here
(setq custom-file (expand-file-name "custom.el" prelude-personal-dir))

;; load the personal settings (this includes `custom-file')
(when (file-exists-p prelude-personal-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-dir)
  (mapc 'load (directory-files prelude-personal-dir 't "^[^#\.].*el$")))

(message "Prelude is ready to do thy bidding, Master %s!" current-user)

(prelude-eval-after-init
 ;; greet the use with some useful tip
 (run-at-time 5 nil 'prelude-tip-of-the-day))

(add-hook 'clojure-mode-hook (lambda ()
                               (clj-refactor-mode 1)
                               (cljr-add-keybindings-with-prefix "C-c C-m")
                               ))



;;; init.el ends here
