# PrimoMCP

An MCP (Model Context Protocol) server that wraps the Ex Libris Primo Search API, enabling LLMs to search library catalogs.

## Prerequisites

- Node.js 22+
- npm
- Docker (for containerized deployment)
- Kubernetes cluster (for K8s deployment)
- Ex Libris Primo API key

## Local Development

```bash
npm install
npm run build
PRIMO_API_KEY=your-key PRIMO_VID=your-vid PRIMO_TAB=your-tab PRIMO_SCOPE=your-scope npm start
```

The server starts on port 3000 (configurable via `PORT`).

### Health Checks

- `GET /healthz` — liveness probe
- `GET /readyz` — readiness probe

### MCP Endpoint

- `POST /mcp` — stateless Streamable HTTP transport (one request per MCP session)

## Docker

```bash
docker build -t primomcp .
docker run -e PRIMO_API_KEY=your-key \
           -e PRIMO_VID=your-vid \
           -e PRIMO_TAB=your-tab \
           -e PRIMO_SCOPE=your-scope \
           -p 3000:3000 primomcp
```

## Kubernetes Deployment

1. Edit `k8s/secret.yaml` with your API key.
2. Edit `k8s/configmap.yaml` with your institution's Primo settings.
3. Edit `k8s/ingress.yaml` with your desired hostname.
4. Apply:

```bash
kubectl apply -f k8s/
```

## MCP Tool: `primo_search`

Search a library catalog via the Primo Search API.

### Inputs

| Parameter | Type | Required | Description |
|---|---|---|---|
| `query` | string | One of `query` or `advancedQuery` required | Simple keyword search |
| `advancedQuery` | string | One of `query` or `advancedQuery` required | Raw Primo `q` format (e.g., `title,contains,machine learning`) |
| `limit` | integer | No | Max results, 1-50 (default 10) |
| `offset` | integer | No | Pagination offset, 0-5000 (default 0) |
| `sort` | string | No | Sort order: `rank`, `title`, `author`, `date`, `date_d`, `date_a` |
| `qInclude` | string | No | Include facet filter |
| `qExclude` | string | No | Exclude facet filter |
| `lang` | string | No | Language code |

### Example

Simple search:
```json
{ "query": "machine learning" }
```

Advanced search:
```json
{ "advancedQuery": "title,contains,machine learning,AND;sub,contains,neural networks", "limit": 5 }
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `PRIMO_API_KEY` | Yes | — | Ex Libris API key |
| `PRIMO_BASE_URL` | No | `https://api-na.hosted.exlibrisgroup.com` | Primo API base URL |
| `PRIMO_VID` | Yes | — | View ID |
| `PRIMO_TAB` | Yes | — | Tab name |
| `PRIMO_SCOPE` | Yes | — | Scope name |
| `PRIMO_INST` | No | — | Institution code (on-premises only) |
| `PORT` | No | `3000` | Server listen port |
