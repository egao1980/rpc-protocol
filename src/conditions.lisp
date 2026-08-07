(in-package #:rpc-protocol)

(define-condition rpc-error (error)
  ((message :initarg :message :reader rpc-error-message :initform nil)
   (code :initarg :code :reader rpc-error-code :initform -32603)
   (data :initarg :data :reader rpc-error-data :initform nil))
  (:report (lambda (c s)
             (format s "rpc error ~a~@[: ~a~]"
                     (rpc-error-code c) (rpc-error-message c)))))

(define-condition rpc-method-not-found (rpc-error) ()
  (:default-initargs :code -32601 :message "Method not found"))

(define-condition rpc-invalid-params (rpc-error) ()
  (:default-initargs :code -32602 :message "Invalid params"))

(defconstant +parse-error+ -32700)
(defconstant +invalid-request+ -32600)
(defconstant +method-not-found+ -32601)
(defconstant +invalid-params+ -32602)
(defconstant +internal-error+ -32603)
