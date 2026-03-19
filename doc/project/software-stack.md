# rAthena Dev Stack Baseline

## Chosen Baseline

This is the stack we are using to get to the first successful login from the
desktop client.

## Server Repo

- Emulator: `rAthena`
- Editable checkout: `/root/dev/rathena`
- Fork remote: `https://github.com/joshhmann/rathena.git`
- Upstream remote: `https://github.com/rathena/rathena.git`
- Main local integration branch: `dev`
- Current validated client branch: `exp/client-2025-06-04`

## Server Build Target

- Build system: `CMake`
- Compiler: `gcc`
- Packet target: `20250604`
- Server mode: Renewal

Why this target:

- it matches the working `2025-06-04` client/exe pair now validated against this container
- it is the first modern client target we have actually confirmed can log in successfully
- it reflects the real current test baseline, not an older fallback

## Client Decision

### Chosen Client For First Test

- Client family: `RagexeRE`
- Packet date: `2025-06-04`
- Goal: keep the desktop client and server aligned on the first confirmed working modern target

### Desktop Setup Expectation

The desktop client should be prepared to match:

- packet version `20250604`
- LAN server IP `192.168.0.132`
- login port `6900`
- char port `6121`
- map port `5121`

### Fallback Option

- fallback stable target: `2022-04-06`
- use this only if the `2025-06-04` client stack becomes too costly to maintain

## Patcher Decision

### Initial Choice

- Patcher: `Thor Patcher`
- Distribution style: simple file-hosted patch pipeline
- Website requirement: none for the initial phase

### Why

- lowest operational overhead for a solo developer
- good enough for pushing client data and executable updates later
- does not block first-login testing

## Database

### Target

- Database engine: `MariaDB`
- Target major version: `10.11`
- Database names: `rathena` and `rathena_log`

### Local Container Baseline

- Current client version in container: `10.11.14-MariaDB`

## Container OS

### Local Container Baseline

- OS: `Ubuntu 24.04.3 LTS`
- Compiler: `gcc 13.3.0`
- tmux: `3.4`

## Local Config Strategy

- tracked `conf/*_athena.conf` files remain close to upstream
- local machine settings are generated into ignored `conf/import/*.txt` files
- local LXC IP should be passed through `SERVER_IP`

Example:

```bash
SERVER_IP=192.168.0.132 bash /root/setup_dev.sh configure
```

## First-Login Test Checklist

1. Install dependencies.
2. Prepare or verify the workspace.
3. Create databases and import SQL.
4. Generate local config with the LXC LAN IP.
5. Build rAthena.
6. Start login, char, and map servers.
7. Prepare a matching `2025-06-04` desktop client.
8. Point the desktop client to `192.168.0.132`.
9. Create or use a test account.
10. Confirm login, character select, and map entry.

## Commands

```bash
bash /root/setup_dev.sh deps
bash /root/setup_dev.sh workspace
bash /root/setup_dev.sh db
SERVER_IP=192.168.0.132 bash /root/setup_dev.sh configure
bash /root/setup_dev.sh build
bash /root/setup_dev.sh start
```

## Decision Notes

- We now have a confirmed working `2025-06-04` login baseline.
- Upstream sync safety is more important than custom config convenience.
- `2022-04-06` remains the fallback stable option if needed.
