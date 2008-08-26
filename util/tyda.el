;;; tyda.el --- Lookup words in swe/eng dictionary at tyda.se
;;
;; Author: Lennart Borgman (lennart O borgman A gmail O com)
;; Created: 2008-08-26T02:51:27+0200 Tue
;; Version: 0.2
;; Last-Updated:
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
;; Lookup swedish or english words in the dictionary at
;;
;;   http://www.tyda.se/
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

(defvar tyda-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(alt mouse-1)] 'tyda-lookup-word)
    (define-key map [(control ?c) ?.] 'tyda-lookup-word)
    map))

(defun tyda-lookup-word (word)
  (interactive (list (or (word-at-point)
                         (read-string "Lookup word: "))))
  (browse-url (concat "http://www.tyda.se/?rid=651940&w=" word)))

(defvar tyda-appmenu-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tyda-lookup]
      (list 'menu-item "Lookup word at point in Tyda"
            'tyda-lookup-word))
    map))

(define-minor-mode tyda-mode
  "Minor mode for looking up words at URL `http://tyda.se/'.
This requires that you are using Firefox as your web browser and
have installed the tyda-add on."
  :lighter " Tyda"
  (if tyda-mode
      (progn
        (require 'appmenu nil t)
        (when (featurep 'appmenu)
          (appmenu-add 'tyda nil tyda-mode "Lookup word" tyda-appmenu-map)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; tyda.el ends here
