;;;### autoload
(defun forth-block-p ()
  "Guess whether the current buffer is a Forth block file."
  (message (format "%s %s" (point-max) (logand (point-max) 1023)))
  (and (eq (logand (point-max) 1023) 1)
       (save-excursion
	 (beginning-of-buffer)
	 (not (search-forward "\n" 1024 t)))))

(defun forth-unblockify ()
  (let ((after-change-functions nil))
    (save-excursion
      (beginning-of-buffer)
      (while (ignore-errors (forward-char 64) t)
	(insert ?\n))
      (let ((delete-trailing-lines t))
	(delete-trailing-whitespace))
      (set-buffer-modified-p nil))))

(defun forth-pad-line ()
  (end-of-line)
  (while (plusp (logand (1- (point)) 63))
    (insert " "))
  (ignore-errors (delete-char 1)
		 (if (looking-at "\n")
		     (insert " "))
		 t))

(defun forth-blockify ()
  (let ((after-change-functions nil))
    (save-excursion
      (beginning-of-buffer)
      (while (forth-pad-line))
      (while (plusp (logand (point) 1023))
	(insert " "))
      (insert " "))))

(defun forth-block-annotations ())

;;; format-alist
'(forth/blocks "Forth blocks" nil forth-unblockify forth-block-annotations
  nil forth-block-mode nil)

(defvar forth-change-newlines)

(defun forth-count-newlines (start end)
  (let ((n 0))
    (save-excursion
      (goto-char start)
      (while (< (point) end)
	(if (looking-at "\n")
	    (incf n))
	(forward-char 1)))
    (message "N = %d" n)
    n))

(defun forth-before-change (start end)
  (setq forth-change-newlines (forth-count-newlines start end)))

(defun forth-after-change (start end z)
  (message "Change: %s %s %s" start end z)
  (setq forth-change-newlines (- (forth-count-newlines start end)
				 forth-change-newlines))
  (message "New lines: %d" forth-change-newlines)
  (cond ((plusp forth-change-newlines)
	 (let ((n (logand (+ (line-number-at-pos) 15) -16)))
	   (save-excursion
	     (goto-line (1+ n))
	     (delete-region (line-beginning-position) (line-end-position))
	     (delete-char 1))))
	((minusp forth-change-newlines)
	 (let ((n (logand (+ (line-number-at-pos) 15) -16)))
	   (save-excursion
	     (goto-line n)
	     (insert "\n")))))
  (save-excursion
    (end-of-line)
    (while (> (- (point) (line-beginning-position)) 64)
      (delete-backward-char 1))))

;;;### autoload
(define-minor-mode forth-block-mode
  "Minor mode for Forth code in blocks."
  :lighter " block"
  (setq require-final-newline nil)
  (forth-unblockify)
  (add-hook (make-local-variable 'before-save-hook) #'forth-blockify)
  (add-hook (make-local-variable 'after-save-hook) #'forth-unblockify)
  (add-to-list (make-local-variable 'before-change-functions)
	       #'forth-before-change)
  (add-to-list (make-local-variable 'after-change-functions)
	       #'forth-after-change))
