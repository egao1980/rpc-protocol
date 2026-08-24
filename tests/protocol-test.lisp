(in-package #:rpc-protocol/tests)

(deftest no-transport-signals
  (let ((rpc-protocol:*rpc-transport* nil))
    (ok (signals (rpc-protocol:rpc-call "ping" nil)
                 'rpc-protocol:rpc-error))))

(deftest encode-roundtrip-shape
  (let* ((req (rpc-protocol:encode-request "sum" #(1 2) :id 7))
         (msg (rpc-protocol:decode-message req)))
    (ok (equal "2.0" (gethash "jsonrpc" msg)))
    (ok (equal "sum" (gethash "method" msg)))
    (ok (= 7 (gethash "id" msg)))))

(deftest encode-false-is-json-boolean
  (let ((h (make-hash-table :test 'equal)))
    (setf (gethash "isError" h) :false)
    (let ((wire (rpc-protocol:encode-response h :id 1)))
      (ok (search "\"isError\":false" (remove #\space wire))))))
