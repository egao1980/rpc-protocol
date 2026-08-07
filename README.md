# rpc-protocol

Lispy **CLOS** RPC for [cl-stack](https://github.com/egao1980/cl-stack) — JSON-RPC 2.0–shaped messages, pluggable transports.

| System | Role | Repo |
|--------|------|------|
| `rpc-protocol` (`stack-rpc`) | Protocol / codec helpers | this repo |
| `rpc-backend-inprocess` | Default transport (same-image) | [`egao1980/rpc-backend-inprocess`](https://github.com/egao1980/rpc-backend-inprocess) |

Not subprocess management — see [`process-protocol`](https://github.com/egao1980/process-protocol).

```lisp
(asdf:load-system "rpc-backend-inprocess")
(stack-rpc:rpc-serve (lambda (method params)
                       (declare (ignore method))
                       params))
(stack-rpc:rpc-call "echo" #(1 2 3))
```

## License

MIT
