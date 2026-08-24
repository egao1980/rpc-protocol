(in-package #:rpc-protocol)

;;; Encoding-agnostic RPC. Interaction modes live here.
;;; Codecs: rpc-protocol-json (JSON-RPC 2.0). Binding: rpc-protocol-grpc.
;;; Wire channel for gRPC stays grpc-protocol; it is not a sibling call API.

(defclass rpc-transport () ())

(defclass rpc-codec () ()
  (:documentation "Wire codec. JSON-RPC: rpc-protocol-json. Later: AG-UI, sexp, …"))

(defclass rpc-stream ()
  ((transport :initarg :transport :reader rpc-stream-transport)
   (method :initarg :method :reader rpc-stream-method)
   (mode :initarg :mode :reader rpc-stream-mode)
   (closed-p :initform nil :accessor rpc-stream-closed-p))
  (:documentation "Open stream for :call-stream / :client-stream / :bidi-stream."))

(defvar *rpc-transport* nil)
(defvar *rpc-codec* nil)

(defparameter +rpc-interaction-modes+
  '(:call-response :notify :call-stream :client-stream :bidi-stream)
  "Supported interaction modes. gRPC maps 1:1 except :notify (no wire equivalent).")

(defun rpc-interaction-mode-p (mode)
  (and (member mode +rpc-interaction-modes+ :test #'eq) t))

(defun %ensure-transport (&optional (transport *rpc-transport*))
  (or transport
      (error 'rpc-error
             :message "*rpc-transport* is nil — load a transport backend"
             :code +internal-error+)))

(defun %ensure-codec (&optional (codec *rpc-codec*))
  (or codec
      (error 'rpc-error
             :message "*rpc-codec* is nil — load rpc-protocol-json (or another codec)"
             :code +internal-error+)))

(defun %unimplemented (what)
  (error 'rpc-error
         :message (format nil "~a not implemented by this transport" what)
         :code +internal-error+))

(defun %ensure-open-stream (stream)
  (when (rpc-stream-closed-p stream)
    (error 'rpc-error :message "stream is closed" :code +internal-error+))
  stream)

;;; ---------------------------------------------------------------------------
;;; Interaction modes — backend GFs
;;; ---------------------------------------------------------------------------

(defgeneric backend-rpc-call (transport method params &key timeout id)
  (:documentation "Unary :call-response. → result. Signals rpc-error on failure."))

(defgeneric backend-rpc-notify (transport method params)
  (:documentation "Fire-and-forget :notify. Returns T."))

(defgeneric backend-rpc-serve (transport handler &key)
  (:documentation "Unary serve. HANDLER is (lambda (method params) → result).
Returns a stop function or the transport."))

(defgeneric backend-rpc-call-stream (transport method params &key timeout id metadata)
  (:documentation "Open :call-stream (one request, many responses). → rpc-stream.
PARAMS is the request; the backend sends it."))

(defgeneric backend-rpc-client-stream (transport method &key timeout id metadata)
  (:documentation "Open :client-stream (many requests, one response). → rpc-stream."))

(defgeneric backend-rpc-bidi-stream (transport method &key timeout id metadata)
  (:documentation "Open :bidi-stream. → rpc-stream."))

(defgeneric backend-rpc-send (stream message &key)
  (:documentation "Send MESSAGE on STREAM."))

(defgeneric backend-rpc-recv (stream &key timeout)
  (:documentation "Receive one message. :eof when the peer is done."))

(defgeneric backend-rpc-close (stream-or-transport &key)
  (:documentation "Release a stream or transport."))

(defgeneric backend-rpc-serve-stream (transport handler &key)
  (:documentation "Stream serve. HANDLER is (lambda (mode method params stream) …)."))

(defmethod backend-rpc-call-stream ((transport rpc-transport) method params
                                    &key timeout id metadata)
  (declare (ignore method params timeout id metadata))
  (%unimplemented "call-stream"))

(defmethod backend-rpc-client-stream ((transport rpc-transport) method
                                      &key timeout id metadata)
  (declare (ignore method timeout id metadata))
  (%unimplemented "client-stream"))

(defmethod backend-rpc-bidi-stream ((transport rpc-transport) method
                                    &key timeout id metadata)
  (declare (ignore method timeout id metadata))
  (%unimplemented "bidi-stream"))

(defmethod backend-rpc-send ((stream rpc-stream) message &key)
  (declare (ignore message))
  (%unimplemented "rpc-send"))

(defmethod backend-rpc-recv ((stream rpc-stream) &key timeout)
  (declare (ignore timeout))
  (%unimplemented "rpc-recv"))

(defmethod backend-rpc-close ((stream rpc-stream) &key)
  (setf (rpc-stream-closed-p stream) t)
  stream)

(defmethod backend-rpc-close ((transport rpc-transport) &key)
  transport)

(defmethod backend-rpc-serve-stream ((transport rpc-transport) handler &key)
  (declare (ignore handler))
  (%unimplemented "rpc-serve-stream"))

;;; ---------------------------------------------------------------------------
;;; Public API
;;; ---------------------------------------------------------------------------

(defun rpc-call (method params &key timeout id (transport *rpc-transport*))
  "Unary :call-response."
  (backend-rpc-call (%ensure-transport transport) method params
                    :timeout timeout :id id))

(defun rpc-notify (method params &key (transport *rpc-transport*))
  "Fire-and-forget :notify."
  (backend-rpc-notify (%ensure-transport transport) method params))

(defun rpc-serve (handler &key (transport *rpc-transport*))
  (backend-rpc-serve (%ensure-transport transport) handler))

(defun rpc-call-stream (method params &key timeout id metadata
                        (transport *rpc-transport*))
  "One request, many responses. Recv with RPC-RECV until :eof."
  (backend-rpc-call-stream (%ensure-transport transport) method params
                           :timeout timeout :id id :metadata metadata))

(defun rpc-client-stream (method &key timeout id metadata
                          (transport *rpc-transport*))
  "Many requests, one response. Send with RPC-SEND, then RPC-RECV."
  (backend-rpc-client-stream (%ensure-transport transport) method
                             :timeout timeout :id id :metadata metadata))

(defun rpc-bidi-stream (method &key timeout id metadata
                        (transport *rpc-transport*))
  "Bidirectional stream. RPC-SEND / RPC-RECV freely."
  (backend-rpc-bidi-stream (%ensure-transport transport) method
                           :timeout timeout :id id :metadata metadata))

(defun rpc-send (stream message &key)
  (backend-rpc-send (%ensure-open-stream stream) message))

(defun rpc-recv (stream &key timeout)
  (backend-rpc-recv (%ensure-open-stream stream) :timeout timeout))

(defun rpc-close (stream-or-transport &key)
  (backend-rpc-close stream-or-transport))

(defun rpc-serve-stream (handler &key (transport *rpc-transport*))
  (backend-rpc-serve-stream (%ensure-transport transport) handler))

(defun rpc-invoke (method params &key (mode :call-response) timeout id metadata
                   (transport *rpc-transport*))
  "Dispatch on MODE. PARAMS is the request for :call-response / :notify /
:call-stream; ignored for :client-stream / :bidi-stream (open the stream, then
RPC-SEND)."
  (unless (rpc-interaction-mode-p mode)
    (error 'rpc-error
           :message (format nil "unknown interaction mode ~s" mode)
           :code +invalid-params+))
  (ecase mode
    (:call-response
     (rpc-call method params :timeout timeout :id id :transport transport))
    (:notify
     (rpc-notify method params :transport transport))
    (:call-stream
     (rpc-call-stream method params :timeout timeout :id id
                      :metadata metadata :transport transport))
    (:client-stream
     (rpc-client-stream method :timeout timeout :id id
                        :metadata metadata :transport transport))
    (:bidi-stream
     (rpc-bidi-stream method :timeout timeout :id id
                      :metadata metadata :transport transport))))

;;; ---------------------------------------------------------------------------
;;; Codec GFs — methods live in format packages (rpc-protocol-json, …)
;;; ---------------------------------------------------------------------------

(defgeneric encode-request-using-codec (codec method params &key id)
  (:documentation "Serialize a request. Default codec is *rpc-codec*."))

(defgeneric encode-notification-using-codec (codec method params &key)
  (:documentation "Serialize a notification."))

(defgeneric encode-response-using-codec (codec result &key id)
  (:documentation "Serialize a successful reply."))

(defgeneric encode-error-response-using-codec (codec code message &key id data)
  (:documentation "Serialize an error reply."))

(defgeneric decode-message-using-codec (codec source)
  (:documentation "Parse SOURCE into a message object (codec-defined)."))

(defun encode-request (method params &key (id 1) (codec *rpc-codec*))
  (encode-request-using-codec (%ensure-codec codec) method params :id id))

(defun encode-notification (method params &key (codec *rpc-codec*))
  (encode-notification-using-codec (%ensure-codec codec) method params))

(defun encode-response (result &key (id 1) (codec *rpc-codec*))
  (encode-response-using-codec (%ensure-codec codec) result :id id))

(defun encode-error-response (code message &key id data (codec *rpc-codec*))
  (encode-error-response-using-codec (%ensure-codec codec) code message
                                    :id id :data data))

(defun decode-message (source &key (codec *rpc-codec*))
  (decode-message-using-codec (%ensure-codec codec) source))
