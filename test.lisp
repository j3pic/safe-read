;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; SECURE-READ
;;;; © Michał "phoe" Herda 2016
;;;; test.lisp

;; No Lisp hackery is complete without tests.
;; To run all tests, compile this file.
(in-package #:secure-read)

;;;; CONDITION-KEY test
(let ((condition (make-condition 'error)))
  (assert (string= 'error (condition-key condition))))

;;;; WITH-TEMP-PACKAGE test
(let ((*package* (find-package "COMMON-LISP")))
  (with-temp-package
    (assert (not (eq *package* (find-package "COMMON-LISP")))) 
    (assert (search "TEMP-PKG-" (package-name *package*)))))

;;;; SAFE-READTABLE test
(let ((*readtable* %safe-readtable%))
  (flet ((errors (string) (signals malformed-input (read-from-string string)))
	 (oerrors (string) (signals (and error (not malformed-input))
			     (read-from-string string)))
	 (generate (char) (coerce (list #\# char) 'string)))
    (let* ((sharpsign-chars '(#\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M
			      #\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z
			      #\# #\' #\( #\) #\* #\= #\\ #\| #\+ #\- #\.))
	   (sharpsign-strings (mapcar #'generate sharpsign-chars))) 
      (mapcar #'oerrors '("\"" "(" ")" "#")) 
      (mapcar #'errors (list* "'" ";" "`" "," sharpsign-strings))
      (eq 'test (read-from-string "#:test")))))

;;;; SAFE-READ-NO-BUFFER and SAFE-READ-BUFFER
(let* ((*max-input-size* 20)
       (data-0 '(#:test))
       (data-1 '(123456789012345678))
       (data-2 '(1234567890123456789))
       (data-3 '(#(1 2 3 4 5)))
       (data-4 (list (cat "a" (string #\Newline) "b"))))
  (labels ((streamify (data) (make-string-input-stream (format nil "~S" data)))
	   (nread (data) (safe-read-no-buffer (streamify data)))
	   (bread (data) (safe-read-buffer (streamify data)))
	   (symbol-test (fn data) (string= (first data) (first (funcall fn data)))))
    ;; SAFE-READ-NO-BUFFER
    (assert (symbol-test #'nread data-0))
    (assert (equal data-1 (nread data-1)))
    (assert (signals input-size-exceeded (nread data-2)))
    (assert (signals malformed-input (nread data-3)))
    (let ((stream (streamify data-4)))
      (assert (null (safe-read-no-buffer stream)))
      (assert (null (safe-read-no-buffer stream))))
    ;; SAFE-READ-BUFFER			
    (assert (symbol-test #'bread data-0))
    (assert (equal data-1 (bread data-1)))
    (assert (signals input-size-exceeded (bread data-2)))
    (assert (signals malformed-input (bread data-3)))
    (let ((stream (streamify data-4)))
      (assert (null (safe-read-buffer stream)))
      (assert (equal data-4 (safe-read-buffer stream))))))

;; TODO add test with leading whitespace

;; SAFE-READ test
(flet ((newline (string) (cat string (string #\Newline))))
  (let* ((strings '("(1 2 3 4)"
                    "    (5 6 7 8)"
                    "(9 8 7"
                    " 6 5 4)"
                    "(3 2 1"
                    "0 1 2"
                    "          "
                    "3 4 5)")) 
	 (string (apply #'cat (mapcar #'newline strings)))
	 (stream (make-string-input-stream string)))
    (assert (equal '(1 2 3 4) (safe-read stream)))
    (assert (equal '(5 6 7 8) (safe-read stream)))
    (assert (null (safe-read stream)))
    (assert (equal '(9 8 7 6 5 4) (safe-read stream)))
    (assert (null (safe-read stream)))
    (assert (null (safe-read stream)))
    (assert (null (safe-read stream)))
    (assert (equal '(3 2 1 0 1 2 3 4 5) (safe-read stream)))))

;; TODO one of the tests hangs indefinitely, check it
