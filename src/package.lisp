(defpackage #:rpc-protocol
  (:use #:cl)
  (:nicknames #:stack-rpc)
  (:export #:rpc-error
           #:rpc-error-message
           #:rpc-error-code
           #:rpc-error-data
           #:rpc-method-not-found
           #:rpc-invalid-params

           #:rpc-transport
           #:*rpc-transport*

           #:rpc-codec
           #:*rpc-codec*

           #:rpc-stream
           #:rpc-stream-transport
           #:rpc-stream-method
           #:rpc-stream-mode
           #:rpc-stream-closed-p

           #:+rpc-interaction-modes+
           #:rpc-interaction-mode-p

           #:backend-rpc-call
           #:backend-rpc-notify
           #:backend-rpc-serve
           #:backend-rpc-call-stream
           #:backend-rpc-client-stream
           #:backend-rpc-bidi-stream
           #:backend-rpc-send
           #:backend-rpc-recv
           #:backend-rpc-close
           #:backend-rpc-serve-stream

           #:rpc-call
           #:rpc-notify
           #:rpc-serve
           #:rpc-call-stream
           #:rpc-client-stream
           #:rpc-bidi-stream
           #:rpc-send
           #:rpc-recv
           #:rpc-close
           #:rpc-serve-stream
           #:rpc-invoke

           #:encode-request-using-codec
           #:encode-notification-using-codec
           #:encode-response-using-codec
           #:encode-error-response-using-codec
           #:decode-message-using-codec

           #:encode-request
           #:encode-notification
           #:encode-response
           #:encode-error-response
           #:decode-message

           #:+parse-error+
           #:+invalid-request+
           #:+method-not-found+
           #:+invalid-params+
           #:+internal-error+))

(in-package #:rpc-protocol)
