# Deploying Sermo (free, self-hosted)

Target: **Oracle Cloud Always-Free** ARM VM. No monthly cost — the only card
interaction is a **$1 refundable verification hold** at signup; staying inside
the Always-Free shapes (ARM VM + block volume + reserved public IP) keeps it at
**$0/month**.

This stack runs everything on one VM via Docker Compose:
- **Sermo** (Phoenix release) — the chat backend + LiveView UI
- **PostgreSQL** — application database
- **Caddy** — reverse proxy that obtains/renews **Let's Encrypt TLS certs
  automatically** (no Cloudflare, no manual cert work). Handles `wss://` for
  LiveView websockets.

Authoritative DNS for your domains lives at **Hurricane Electric Free DNS
(dns.he.net)** — your laptop Technitium server stays up but isn't the public
authoritative source (registrar/glue constraints). So the only DNS change is an
**A record at HE** pointing your Sermo host at the Oracle VM's reserved IP.
Firebase keeps hosting the static React site (`vzdev.indevs.in`) separately.
Firebase Hosting cannot proxy to an external server, so Sermo's domain/cert is
handled by Caddy here, not Firebase.

## 1. Oracle Always-Free VM

1. Sign up at oracle.com/cloud (card needed for the $1 hold only).
2. Create a VM in a region with Always-Free capacity:
   - Image: Ubuntu 22.04/24.04
   - Shape: `VM.Standard.A1.Flex` — **stay within free allowance**:
     up to 4 OCPU / 24 GB RAM total. 1 OCPU + 6 GB is enough; use 2 OCPU + 12 GB
     for headroom.
   - Boot volume: keep within the free 200 GB block-volume allowance.
3. **Reserve a public IP** (Networking → Reserved IPs) so it never changes —
   this is free under Always-Free.
4. Open the VM's VCN security list / iptables for: `22` (SSH), `80`, `443`
   (Caddy/TLS), and `53/tcp` + `53/udp` (your DNS server).

## 2. Install Docker

```bash
sudo apt-get update && sudo apt-get install -y docker.io docker-compose-plugin
sudo usermod -aG docker $USER   # re-login afterwards
```

## 3. Deploy Sermo

```bash
git clone <your-repo> sermo && cd sermo
cp .env.example .env
# edit .env: DB_PASSWORD, SECRET_KEY_BASE, RECOVERY_ENCRYPTION_KEY, PHX_HOST
docker compose up -d --build
```

Generate the secrets locally first:
```bash
mix phx.gen.secret
mix run -e 'IO.puts(:crypto.strong_rand_bytes(32) |> Base.encode64())'
```

## 4. Point your domain at the VM

In **Hurricane Electric Free DNS (dns.he.net)**, set an A record for your Sermo
host (e.g. `chat.indevs.in` or a new free domain) → the Oracle VM's reserved
public IP. Caddy will fetch the certificate as soon as port 80 is reachable.

Update `Caddyfile` with the real domain (and `email` for ACME), then:
```bash
docker compose up -d caddy
```

Your laptop Technitium keeps doing whatever local/resolver role it does, but the
Sermo traffic now terminates at Oracle and the public zone lives at HE.

## Notes

- Single-node PubSub/Presence works as-is (no clustering needed).
- To back up: snapshot the boot volume, or `pg_dump` the `db` service.
- Scale down `POOL_SIZE` in `.env` if memory is tight.
