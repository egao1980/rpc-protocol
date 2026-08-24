# rpc-protocol

Lispy **CLOS** RPC for [cl-stack](https://github.com/egao1980/cl-stack) — encoding-agnostic **interaction modes** + pluggable codec.

| System | Role | Repo |
|--------|------|------|
| `rpc-protocol` (`stack-rpc`) | Modes + codec GFs | this repo |
| `rpc-protocol-json` (`stack-rpc-json`) | JSON-RPC 2.0 codec | [`egao1980/rpc-protocol-json`](https://github.com/egao1980/rpc-protocol-json) |
| `rpc-protocol-grpc` (`stack-rpc-grpc`) | gRPC binding (`rpc-transport` over `grpc-protocol`) | [`egao1980/rpc-protocol-grpc`](https://github.com/egao1980/rpc-protocol-grpc) |
| `rpc-backend-inprocess` | Same-image unary transport | [`egao1980/rpc-backend-inprocess`](https://github.com/egao1980/rpc-backend-inprocess) |

Not subprocess management — see [`process-protocol`](https://github.com/egao1980/process-protocol). gRPC **wire** (channel / status / HTTP2 / C-core) stays [`grpc-protocol`](https://github.com/egao1980/grpc-protocol); call it through `rpc-protocol-grpc`.

## Modes

| Mode | API | Shape |
|------|-----|--------|
| `:call-response` | `rpc-call` | one request → one reply |
| `:notify` | `rpc-notify` | one request, no reply |
| `:call-stream` | `rpc-call-stream` | one request → many replies (`rpc-recv` until `:eof`) |
| `:client-stream` | `rpc-client-stream` | many `rpc-send` → one reply |
| `:bidi-stream` | `rpc-bidi-stream` | `rpc-send` / `rpc-recv` freely |

`rpc-invoke` dispatches on `:mode`. Default stream methods on `rpc-transport` signal unimplemented — unary transports keep working.

```lisp
(asdf:load-system "rpc-protocol-json")
(asdf:load-system "rpc-backend-inprocess")
(stack-rpc:rpc-serve (lambda (method params)
                       (declare (ignore method))
                       params))
(stack-rpc:rpc-call "echo" #(1 2 3))
(stack-rpc:rpc-invoke "echo" #(1 2 3) :mode :call-response)
```

`encode-request` / `decode-message` dispatch on `*rpc-codec*`. Load `rpc-protocol-json` for JSON-RPC 2.0. Do **not** wrap AG-UI in a JSON-RPC envelope — that is `:call-stream` with a later codec.

## License

MIT
