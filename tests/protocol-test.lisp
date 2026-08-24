(in-package #:rpc-protocol/tests)

(defclass mock-transport (rpc-protocol:rpc-transport)
  ((calls :initform nil :accessor mock-calls)))

(defclass mock-stream (rpc-protocol:rpc-stream)
  ((inbox :initarg :inbox :initform nil :accessor mock-inbox)
   (outbox :initform nil :accessor mock-outbox)))

(defmethod rpc-protocol:backend-rpc-call ((transport mock-transport) method params
                                          &key timeout id)
  (push (list :call-response method params timeout id) (mock-calls transport))
  (list :ok method params))

(defmethod rpc-protocol:backend-rpc-notify ((transport mock-transport) method params)
  (push (list :notify method params) (mock-calls transport))
  t)

(defmethod rpc-protocol:backend-rpc-serve ((transport mock-transport) handler &key)
  (push (list :serve handler) (mock-calls transport))
  transport)

(defmethod rpc-protocol:backend-rpc-call-stream ((transport mock-transport) method params
                                                 &key timeout id metadata)
  (declare (ignore timeout id))
  (push (list :call-stream method params) (mock-calls transport))
  (make-instance 'mock-stream
                 :transport transport
                 :method method
                 :mode :call-stream
                 :inbox (copy-list (getf metadata :inbox))))

(defmethod rpc-protocol:backend-rpc-client-stream ((transport mock-transport) method
                                                   &key timeout id metadata)
  (declare (ignore timeout id))
  (push (list :client-stream method) (mock-calls transport))
  (make-instance 'mock-stream
                 :transport transport
                 :method method
                 :mode :client-stream
                 :inbox (copy-list (getf metadata :inbox))))

(defmethod rpc-protocol:backend-rpc-bidi-stream ((transport mock-transport) method
                                                 &key timeout id metadata)
  (declare (ignore timeout id))
  (push (list :bidi-stream method) (mock-calls transport))
  (make-instance 'mock-stream
                 :transport transport
                 :method method
                 :mode :bidi-stream
                 :inbox (copy-list (getf metadata :inbox))))

(defmethod rpc-protocol:backend-rpc-send ((stream mock-stream) message &key)
  (push message (mock-outbox stream))
  message)

(defmethod rpc-protocol:backend-rpc-recv ((stream mock-stream) &key timeout)
  (declare (ignore timeout))
  (or (pop (mock-inbox stream)) :eof))

(deftest no-transport-signals
  (let ((rpc-protocol:*rpc-transport* nil))
    (ok (signals (rpc-protocol:rpc-call "ping" nil)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-call-stream "run" nil)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-invoke "ping" nil :mode :bidi-stream)
                 'rpc-protocol:rpc-error))))

(deftest no-codec-signals
  (let ((rpc-protocol:*rpc-codec* nil))
    (ok (signals (rpc-protocol:encode-request "sum" #(1 2) :id 7)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:decode-message "{}")
                 'rpc-protocol:rpc-error))))

(deftest default-stream-ops-unimplemented
  (let ((tr (make-instance 'rpc-protocol:rpc-transport))
        (st (make-instance 'rpc-protocol:rpc-stream
                           :transport nil :method "x" :mode :call-stream)))
    (ok (signals (rpc-protocol:rpc-call-stream "run" nil :transport tr)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-client-stream "up" :transport tr)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-bidi-stream "chat" :transport tr)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-serve-stream #'identity :transport tr)
                 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-send st 1) 'rpc-protocol:rpc-error))
    (ok (signals (rpc-protocol:rpc-recv st) 'rpc-protocol:rpc-error))
    (ok (eq tr (rpc-protocol:rpc-close tr)))
    (ok (rpc-protocol:rpc-stream-closed-p (rpc-protocol:rpc-close st)))))

(deftest interaction-modes
  (ok (equal '(:call-response :notify :call-stream :client-stream :bidi-stream)
             rpc-protocol:+rpc-interaction-modes+))
  (ok (rpc-protocol:rpc-interaction-mode-p :call-stream))
  (ok (not (rpc-protocol:rpc-interaction-mode-p :foo)))
  (ok (signals (rpc-protocol:rpc-invoke "x" nil :mode :nope)
               'rpc-protocol:rpc-error)))

(deftest invoke-dispatches
  (let* ((tr (make-instance 'mock-transport))
         (rpc-protocol:*rpc-transport* tr))
    (ok (equal '(:ok "echo" (1 2)) (rpc-protocol:rpc-invoke "echo" '(1 2))))
    (ok (eq t (rpc-protocol:rpc-invoke "ping" nil :mode :notify)))
    (let ((s (rpc-protocol:rpc-invoke "RunAgent" '(:in)
                                      :mode :call-stream
                                      :metadata '(:inbox (a b)))))
      (ok (eq :call-stream (rpc-protocol:rpc-stream-mode s)))
      (ok (equal "RunAgent" (rpc-protocol:rpc-stream-method s)))
      (ok (eq 'a (rpc-protocol:rpc-recv s)))
      (ok (eq 'b (rpc-protocol:rpc-recv s)))
      (ok (eq :eof (rpc-protocol:rpc-recv s)))
      (rpc-protocol:rpc-close s)
      (ok (rpc-protocol:rpc-stream-closed-p s))
      (ok (signals (rpc-protocol:rpc-recv s) 'rpc-protocol:rpc-error)))
    (let ((s (rpc-protocol:rpc-invoke "Upload" nil :mode :client-stream)))
      (ok (eq :client-stream (rpc-protocol:rpc-stream-mode s)))
      (ok (eq 'chunk (rpc-protocol:rpc-send s 'chunk)))
      (ok (equal '(chunk) (mock-outbox s)))
      (rpc-protocol:rpc-close s))
    (let ((s (rpc-protocol:rpc-invoke "Chat" nil :mode :bidi-stream
                                      :metadata '(:inbox (hi)))))
      (ok (eq :bidi-stream (rpc-protocol:rpc-stream-mode s)))
      (ok (eq 'hi (rpc-protocol:rpc-recv s)))
      (ok (eq 'yo (rpc-protocol:rpc-send s 'yo)))
      (rpc-protocol:rpc-close s))
    (ok (equal '(:bidi-stream "Chat")
               (first (mock-calls tr))))))
