(defsystem "rpc-protocol"
  :version "0.2.0"
  :description "CLOS RPC protocol for cl-stack (interaction modes + codec GFs; encoding-agnostic)"
  :author "egao1980"
  :license "MIT"
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "protocol"))
  :in-order-to ((test-op (test-op "rpc-protocol/tests"))))

(defsystem "rpc-protocol/tests"
  :depends-on ("rpc-protocol" "rove")
  :properties (:cl-repo (:ci (:with ("dissect") :sources (("dissect" :ql)))))
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "protocol-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
