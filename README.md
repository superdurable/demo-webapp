# Dataset Deal Web App

一个可独立运行的全栈 Dex 示例。浏览器前端用于编辑数据集交易流程、创建买家执行并发送条件消息；Go 服务同时运行 REST API 和 Dex Worker；流程定义存储在 PostgreSQL，运行状态由 Dex 持久化。

```text
Browser ── HTTP ──> Go API + embedded frontend
                         │
                         ├── PostgreSQL: seller process definitions
                         └── Dex FlowService <──> Go Worker
```

## Local development

先安装 Docker Desktop、Go 1.24+ 和 [Dex CLI](https://github.com/superdurable/dex)。然后运行：

```bash
make run
```

该命令会构建 Go 服务、启动本地 PostgreSQL、在没有已有 Dex 开发环境时启动 `dexcli dev`，并在 `http://127.0.0.1:8080` 提供应用。按 Ctrl-C 会停止本次启动的 Dex 进程；PostgreSQL 会保留，使用 `make postgres-down` 停止它。

常用命令：

```bash
make build          # build bin/dataset-deal-webapp
make test           # run Go tests
make postgres-up    # only start PostgreSQL
make docker-build   # build dataset-deal-webapp:local
```

## Deployment

`Dockerfile` 构建的是最小化生产应用镜像。它不在容器内启动 Dex 或 PostgreSQL；请为每个环境提供受管的 PostgreSQL 和 Dex FlowService，并设置：

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | PostgreSQL connection URL for process definitions. |
| `DEX_FLOW_SERVICE_ADDRESS` | Dex FlowService plaintext gRPC address. |
| `DEX_WORKER_BIND_ADDRESS` | WorkerService listener; default `0.0.0.0:8803`. |
| `DEX_WORKER_TARGET` | Address reachable by Dex for callbacks to this app's WorkerService. |
| `HTTP_ADDRESS` | HTTP listener; default `0.0.0.0:8080`. |

Expose port 8080 to users and make port 8803 reachable from the Dex FlowService. In production, `DEX_WORKER_TARGET` should be the stable DNS name and port that Dex can reach, rather than a loopback address.

The application initializes its PostgreSQL schema idempotently at startup. Existing deal executions keep an immutable Dex snapshot of their process, so later edits to a seller's PostgreSQL process affect only new executions.
