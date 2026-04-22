# Prefect Auth Proxy

Minimal nginx reverse proxy that puts basic authentication in front of a Prefect UI deployed on Railway.

## Railway Environment Variables

| Variable          | Required | Example                                    | Description                          |
|-------------------|----------|--------------------------------------------|--------------------------------------|
| `AUTH_USER`       | Yes      | `admin`                                    | Username for basic auth              |
| `AUTH_PASSWORD`   | Yes      | `s3cureP@ss`                               | Password for basic auth              |
| `UPSTREAM_HOST`   | Yes      | `prefect-server.railway.internal`          | Prefect server internal hostname     |
| `UPSTREAM_PORT`   | Yes      | `4200`                                     | Prefect server port                  |
| `PORT`            | Auto     | `8080`                                     | Set automatically by Railway         |

## Deploy to Railway

1. Push this folder to a GitHub repo (or deploy directly with `railway up`).

2. In the Railway dashboard, create a new service from this repo.

3. Set the four required environment variables on the service.

4. Assign the **public domain** to this proxy service.

5. **Remove the public domain** from your Prefect server service
   (it should only be reachable via `*.railway.internal`).

6. Set the health check path to `/health` in the proxy service settings.

## How it works

- The entrypoint reads `/etc/resolv.conf` to pick up Railway's DNS resolver.
- `envsubst` injects all connection details into the nginx config at container start.
- nginx resolves the upstream hostname at request time (not just at boot),
  so it survives Prefect service redeploys that change the internal IP.
- WebSocket headers are forwarded so the Prefect UI live-updates work.
- The `/health` endpoint is unauthenticated so Railway can health-check the proxy.

## Local testing

```bash
docker build -t prefect-auth-proxy .

docker run --rm -p 8080:8080 \
  -e AUTH_USER=admin \
  -e AUTH_PASSWORD=test123 \
  -e UPSTREAM_HOST=host.docker.internal \
  -e UPSTREAM_PORT=4200 \
  prefect-auth-proxy
```