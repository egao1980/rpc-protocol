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

           #:backend-rpc-call
           #:backend-rpc-notify
           #:backend-rpc-serve

           #:rpc-call
           #:rpc-notify
           #:rpc-serve

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
