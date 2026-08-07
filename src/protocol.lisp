(in-package #:rpc-protocol)

;;; JSON-RPC 2.0–shaped. Process/stdio transports live in backends.
;;; Wave-1 codec = JSON via yason (serdes hard-wire later).

(defclass rpc-transport () ())

(defvar *rpc-transport* nil)

(defun %ensure-transport (&optional (transport *rpc-transport*))
  (or transport
      (error 'rpc-error
             :message "*rpc-transport* is nil — load rpc-backend-inprocess"
             :code +internal-error+)))

(defgeneric backend-rpc-call (transport method params &key timeout id)
  (:documentation "→ result. Signals rpc-error on failure."))

(defgeneric backend-rpc-notify (transport method params)
  (:documentation "Fire-and-forget. Returns T."))

(defgeneric backend-rpc-serve (transport handler &key)
  (:documentation "HANDLER is (lambda (method params) → result).
Returns a stop function or the transport."))

(defun rpc-call (method params &key timeout id (transport *rpc-transport*))
  (backend-rpc-call (%ensure-transport transport) method params
                    :timeout timeout :id id))

(defun rpc-notify (method params &key (transport *rpc-transport*))
  (backend-rpc-notify (%ensure-transport transport) method params))

(defun rpc-serve (handler &key (transport *rpc-transport*))
  (backend-rpc-serve (%ensure-transport transport) handler))

;;; ---------------------------------------------------------------------------
;;; Message codec (JSON-RPC 2.0 object as hash-table / alist helpers)
;;; ---------------------------------------------------------------------------

(defun %json (obj)
  (with-output-to-string (s)
    (yason:encode obj s)))

(defun %parse (string)
  (yason:parse string :object-as :hash-table :json-arrays-as-vectors t))

(defun encode-request (method params &key (id 1) (jsonrpc "2.0"))
  (%json (let ((h (make-hash-table :test 'equal)))
           (setf (gethash "jsonrpc" h) jsonrpc
                 (gethash "method" h) method
                 (gethash "params" h) (or params #())
                 (gethash "id" h) id)
           h)))

(defun encode-notification (method params &key (jsonrpc "2.0"))
  (%json (let ((h (make-hash-table :test 'equal)))
           (setf (gethash "jsonrpc" h) jsonrpc
                 (gethash "method" h) method
                 (gethash "params" h) (or params #()))
           h)))

(defun encode-response (result &key (id 1) (jsonrpc "2.0"))
  (%json (let ((h (make-hash-table :test 'equal)))
           (setf (gethash "jsonrpc" h) jsonrpc
                 (gethash "result" h) result
                 (gethash "id" h) id)
           h)))

(defun encode-error-response (code message &key id data (jsonrpc "2.0"))
  (%json (let ((h (make-hash-table :test 'equal))
               (err (make-hash-table :test 'equal)))
           (setf (gethash "code" err) code
                 (gethash "message" err) message)
           (when data (setf (gethash "data" err) data))
           (setf (gethash "jsonrpc" h) jsonrpc
                 (gethash "error" h) err
                 (gethash "id" h) id)
           h)))

(defun decode-message (string)
  "→ hash-table message."
  (%parse string))
