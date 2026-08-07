(defsystem "rpc-protocol"
  :version "0.1.0"
  :description "CLOS RPC protocol for cl-stack (JSON-RPC–shaped; transports + codecs)"
  :author "egao1980"
  :license "MIT"
  :depends-on ("yason")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "protocol"))
  :in-order-to ((test-op (test-op "rpc-protocol/tests"))))

(defsystem "rpc-protocol/tests"
  :depends-on ("rpc-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "protocol-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
