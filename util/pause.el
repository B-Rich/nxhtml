;;; pause.el --- Take a break!
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2008-01-19 Sat
(defconst pause:version "0.64");; Version:
;; Last-Updated: 2009-08-04 Tue
;; URL:
;; Keywords:
;; Compatibility:
;;
;; Features that might be required by this library:
;;
;;   None
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;; If you are using Emacs then don't you need a little reminder to
;; take a pause? Add to your .emacs
;;
;;   (require 'pause)
;;
;; and do
;;
;;   M-x customize-group RET pause RET
;;
;; and set `pause-mode' to t.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

;;;###autoload
(defgroup pause nil
  "Customize your health personal Emacs health saver!"
  :group 'convenience)

(defcustom pause-after-minutes 15
  "Pause after this number of minutes."
  :type 'integer
  :group 'pause)

(defcustom pause-text-color "sienna"
  "Color of text in pause window."
  :type 'color
  :group 'pause)

(defcustom pause-prompt1-color "DarkOrange1"
  "Background color of first pause prompt."
  :type 'color
  :group 'pause)

(defcustom pause-prompt2-color "GreenYellow"
  "Background color of second pause prompt."
  :type 'color
  :group 'pause)

(defcustom pause-message-color "yellow"
  "Background color of pause messages."
  :type 'color
  :group 'pause)

(defcustom pause-break-text
  (concat "\n\tHi there,"
          "\n\tYou are worth a PAUSE!"
          "\n\nTry some mindfulness:"
          "\n\t- Look around and observe."
          "\n\t- Listen."
          "\n\t- Feel your body.")
  "Text to show during pause."
  :type 'integer
  :group 'pause)

(defvar pause-default-img-dir
  (let* ((this-file (or load-file-name
                       buffer-file-name))
         (this-dir (file-name-directory this-file)))
    (expand-file-name "../etc/img/pause/" this-dir)))

(defcustom pause-img-dir pause-default-img-dir
  "Image directory for pause."
  :type 'directory
  :group 'pause)

(defvar pause-timer nil)
(defvar pause-idle-timer nil)

(defun pause-dont-save-me ()
  (when (timerp pause-timer) (cancel-timer pause-timer)))

(defun pause-start-timer (sec)
  (when (timerp pause-idle-timer) (cancel-timer pause-idle-timer))
  (setq pause-idle-timer nil)
  (when (timerp pause-timer) (cancel-timer pause-timer))
  (setq pause-timer (run-with-timer sec nil 'pause-pre-break)))

(defun pause-one-minute ()
  "Give you another minute ..."
  (pause-start-timer 60)
  (message (propertize " OK, I will come back in a minute! -- greatings from pause"
                       'face (list :background pause-message-color))))

(defun pause-save-me ()
  (pause-start-timer (* 60 pause-after-minutes))
  (message (propertize " OK, I will save you again in %d minutes! -- greatings from pause "
                       'face (list :background pause-message-color))
           pause-after-minutes))

(defun pause-ask-user ()
  (if (or isearch-mode
          (active-minibuffer-window))
      (pause-start-timer 10)
    (let* ((map (copy-keymap minibuffer-local-map))
           (minibuffer-local-map map)
           (use-dialog-box nil)
           (minibuffer-prompt-properties
            (copy-sequence minibuffer-prompt-properties))
           (msg1
            (concat
             " :-) Sorry to disturb you!\n\n"
             " Do you want me to take a break now? ... "))
           (msg2
            (concat
             " :-) Take a break now, then come back later and answer!\n\n"
             " Do you want me to save you again? That is my job ... ")))
      ;;(define-key map [(control ?g)] 'ignore)
      (plist-put minibuffer-prompt-properties 'face
                 (list :background pause-prompt1-color))
      (if (yes-or-no-p msg1)
          (progn
            (plist-put minibuffer-prompt-properties 'face
                       (list :background pause-prompt2-color))
            (y-or-n-p msg2))
        'one-minute))))

(defvar pause-idle-delay 15)

(defun pause-pre-break ()
  (setq pause-timer nil)
  (condition-case err
      (save-match-data ;; runs in timer
        (if pause-idle-delay
            (setq pause-idle-timer (run-with-idle-timer pause-idle-delay nil 'pause-break-in-timer))
          (setq pause-idle-timer (run-with-idle-timer 5 nil 'pause-break-in-timer))))
    (error
     (lwarn 'pause-pre-break
            :error "%s" (error-message-string err)))))

(defvar pause-saved-frame-config nil)
;;(make-variable-frame-local 'pause-saved-frame-config)

(defvar pause-break-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(control meta shift ?p)] 'pause-break-exit)
    map))

(defvar pause-buffer nil)

(define-derived-mode pause-break-mode nil "Pause"
  "Mode used during pause.

\\[pause-break-exit]"
  (set (make-local-variable 'buffer-read-only) t)
  ;;(set (make-local-variable 'cursor-type) nil)
  ;; Fix-me: workaround for emacs bug
  (run-with-idle-timer 0 nil 'pause-hide-cursor))

;; (defun pause-kill-buffer ()
;;   ;; runs in timer, save-match-data
;;   (when (buffer-live-p pause-buffer) (kill-buffer pause-buffer)))

(defvar pause-break-exit-active nil)

(defun pause-break ()
  (pause-cancel-timer)
  (let ((wcfg (current-frame-configuration))
        (old-mode-line-bg (face-attribute 'mode-line :background))
        old-frame-bg-color
        old-frame-left-fringe
        old-frame-right-fringe
        old-frame-tool-bar-lines
        old-frame-menu-bar-lines
        old-frame-vertical-scroll-bars)
    (set-face-attribute 'mode-line nil :background "sienna")
    (dolist (f (frame-list))
      (add-to-list 'old-frame-bg-color (cons f (frame-parameter f 'background-color)))
      (add-to-list 'old-frame-left-fringe (cons f (frame-parameter f 'left-fringe)))
      (add-to-list 'old-frame-right-fringe (cons f (frame-parameter f 'right-fringe)))
      (add-to-list 'old-frame-tool-bar-lines (cons f (frame-parameter f 'tool-bar-lines)))
      (add-to-list 'old-frame-menu-bar-lines (cons f (frame-parameter f 'menu-bar-lines)))
      (add-to-list 'old-frame-vertical-scroll-bars (cons f (frame-parameter f 'vertical-scroll-bars))))

    (run-with-idle-timer 0 nil 'pause-break-show)
    (setq pause-break-exit-active nil)
    (while (not pause-break-exit-active)
      (recursive-edit)
      (unless pause-break-exit-active
        (add-hook 'window-configuration-change-hook 'pause-break-exit)))

    ;;(set-frame-parameter nil 'background-color "white")
    (kill-buffer pause-buffer)
    (set-face-attribute 'mode-line nil :background old-mode-line-bg)
    (dolist (f (frame-list))
      (set-frame-parameter f 'background-color
                           (cdr (assq f old-frame-bg-color)))
      (set-frame-parameter f 'left-fringe
                           (cdr (assq f old-frame-left-fringe)))
      (set-frame-parameter f 'right-fringe
                           (cdr (assq f old-frame-right-fringe)))
      (set-frame-parameter f 'tool-bar-lines
                           (cdr (assq f old-frame-tool-bar-lines)))
      (set-frame-parameter f 'menu-bar-lines
                           (cdr (assq f old-frame-menu-bar-lines)))
      (set-frame-parameter f 'vertical-scroll-bars
                           (cdr (assq f old-frame-vertical-scroll-bars)))
      )
    (set-frame-configuration wcfg)))


(defun pause-break-show ()
  (with-current-buffer (setq pause-buffer
                             (get-buffer-create "* P A U S E *"))
    (when (= 0 (buffer-size))
      (pause-break-mode)
      (setq left-margin-width 25)
      (let ((inhibit-read-only t))
        (pause-insert-img)
        (insert (propertize pause-break-text
                            'face (list 'bold
                                        :height 1.5
                                        :foreground pause-text-color)))
        (insert (propertize "\n\nTo exit switch buffer\n"
                            'face (list :foreground "yellow")))
        (add-text-properties (point-min) (point-max) (list 'keymap (make-sparse-keymap)))
        (dolist (m '(hl-needed-mode))
          (when (and (boundp m) (symbol-value m))
            (funcall m -1))))))
    (dolist (f (frame-list))
      (let* ((avail-width (- (display-pixel-width)
                             (* 2 (frame-parameter f 'border-width))
                             (* 2 (frame-parameter f 'internal-border-width))))
             (avail-height (- (display-pixel-height)
                              (* 2 (frame-parameter f 'border-width))
                              (* 2 (frame-parameter f 'internal-border-width))))
             (cols (/ avail-width (frame-char-width)))
             (rows (- (/ avail-height (frame-char-height)) 2)))
        ;;(set-frame-parameter (selected-frame) 'fullscreen 'fullboth)
        ;;(set-frame-parameter (selected-frame) 'fullscreen 'maximized)
        (with-selected-frame f
          (delete-other-windows)
          (with-selected-window (frame-first-window)
            (switch-to-buffer pause-buffer)
            (goto-char 1)))
        (modify-frame-parameters f
                                 (list '(background-color . "orange")
                                       '(left-fringe . 0)
                                       '(right-fringe . 0)
                                       '(tool-bar-lines . 0)
                                       '(menu-bar-lines . 0)
                                       '(vertical-scroll-bars . nil)
                                       '(left . 0)
                                       '(top . 0)
                                       (cons 'width cols)
                                       (cons 'height rows)
                                       ))))
  (run-with-idle-timer 0 nil 'pause-break-message)
  (setq pause-break-exit-active nil)
  (add-hook 'window-configuration-change-hook 'pause-break-exit)
  (run-with-idle-timer 2 nil 'pause-break-exit-activate))


(defun pause-break-message ()
  (message "%s" (propertize "Please take a pause!" 'face 'mode-line-inactive)))

(defun pause-break-exit-activate ()
  (setq pause-break-exit-active t)
  (message nil)
  (with-current-buffer pause-buffer
    (let ((inhibit-read-only t))
      (add-text-properties (point-min) (point-max) (list 'keymap nil)))))

(defun pause-break-exit ()
  (interactive)
  (when t ;pause-break-exit-active
    (remove-hook 'window-configuration-change-hook 'pause-break-exit)
    (exit-recursive-edit)))

(defun pause-insert-img ()
  (let* ((inhibit-read-only t)
        img
        src
        (slice '(0 0 200 300))
        (imgs (directory-files pause-img-dir nil nil t))
        skip
        )
    (setq imgs (delete nil
                       (mapcar (lambda (d)
                                 (unless (file-directory-p d) d))
                               imgs)))
    ;;(message "imgs=%s" imgs)
    (setq skip (random (length imgs)))
    (while (> skip 0)
      (setq skip (1- skip))
      (setq imgs (cdr imgs)))
    (setq src (expand-file-name (car imgs) pause-img-dir))
    (if (file-exists-p src)
        (condition-case err
            (setq img (create-image src nil nil
                                    :relief 1
                                    ;;:margin inlimg-margins
                                    ))
          (error (setq img (error-message-string err))))
      (setq img (concat "Image not found: " src)))
    (if (stringp img)
        (insert img)
      (insert-image img nil 'left-margin slice)
      )
    ;;(message "After insert img=%s" img)
    ))

(defun pause-hide-cursor ()
  ;; runs in timer, save-match-data
  (with-current-buffer pause-buffer
    (set (make-local-variable 'cursor-type) nil)))

(defun pause-cancel-timer ()
  (when (timerp pause-idle-timer) (cancel-timer pause-idle-timer))
  (setq pause-idle-timer nil))

(defun pause-break-in-timer ()
  (save-match-data ;; runs in timer
    (pause-cancel-timer)
    (if (or (active-minibuffer-window)
            (and (boundp 'edebug-active)
                 edebug-active))
        (let ((pause-idle-delay 5))
          (pause-pre-break))
      (let ((there-was-an-error nil))
        ;;(message "calling break in timer")
        (condition-case err
            (pause-break)
          (error
           (message "pause-break-in-timer: %s" (error-message-string err))
           (setq there-was-an-error t)))
        (when there-was-an-error
          (condition-case err
              (progn
                (select-frame last-event-frame)
                (let ((pause-idle-delay nil))
                  (pause-pre-break)))
            (error
             (lwarn 'pause-break-in-timer2 :error "%s" (error-message-string err))
             )))))))

;;;###autoload
(define-minor-mode pause-mode
  "This minor mode tries to make you take a break!
To customize it see:

 `pause-after-minutes'
 `pause-text-color'
 `pause-prompt1-color'
 `pause-prompt2-color'
 `pause-message-color'
"
  :global t
  :group 'pause
  (if pause-mode
      (pause-save-me)
    (pause-dont-save-me)))

(provide 'pause)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; pause.el ends here
