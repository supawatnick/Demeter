# Demeter Development Access Runbook

## Source of truth

This file documents how development access for Demeter is routed.

## Topology

- ntap-office host / relay: `inwjud`
- Relay IP: `10.10.110.72`
- Demeter development server alias: `nizki-demeter`
- Demeter development server IP: `10.10.110.75`
- Remote hostname observed: `ubuntu24`
- Remote user: `root`

Required path:

```text
ChatGPT -> ntap-office -> inwjud (10.10.110.72) -> SSH -> nizki-demeter (10.10.110.75)
```

## Critical operating rule

**Never develop Demeter on inwjud.**

The `inwjud` machine is only a command relay.

Do not clone, install dependencies, build, test, run Docker, run Prisma migrations, start Next.js/NestJS, or run Demeter application workloads on `inwjud`.

All Demeter development work must execute on `10.10.110.75`.

## SSH identity on inwjud

Expected files:

```text
/root/.ssh/demeter_nizki_ed25519
/root/.ssh/demeter_nizki_ed25519.pub
/root/.ssh/config
```

The private key must never be committed to this repository.

Expected SSH alias configuration:

```sshconfig
Host nizki-demeter
  HostName 10.10.110.75
  User root
  IdentityFile /root/.ssh/demeter_nizki_ed25519
  IdentitiesOnly yes
  StrictHostKeyChecking accept-new
```

Recommended permissions:

```text
/root/.ssh                         700
/root/.ssh/config                  600
/root/.ssh/demeter_nizki_ed25519  600
/root/.ssh/demeter_nizki_ed25519.pub 644
```

The matching public key must exist in `/root/.ssh/authorized_keys` on `10.10.110.75`.

## Connection validation

From inwjud:

```bash
ssh nizki-demeter 'hostname && hostname -I && whoami'
```

Expected identity:

```text
hostname: ubuntu24
IP includes: 10.10.110.75
user: root
```

A successful connection was verified on 2026-10-03.

Before installs, builds, database changes, Docker operations, deployments, or other disruptive work, verify the target again.

## Direct-key fallback

If the alias fails but the key is present:

```bash
ssh -i /root/.ssh/demeter_nizki_ed25519 \
  -o IdentitiesOnly=yes \
  root@10.10.110.75 \
  'hostname && hostname -I && whoami'
```

If this succeeds while `ssh nizki-demeter` fails, repair `/root/.ssh/config`.

## Troubleshooting

### Could not resolve hostname nizki-demeter

Check that `/root/.ssh/config` contains the exact `Host nizki-demeter` block above and that the file permission is 600.

Then retry:

```bash
ssh nizki-demeter 'hostname && hostname -I && whoami'
```

### Identity file not accessible / No such file

Check:

```bash
ls -la /root/.ssh/
```

The Demeter private/public key pair must exist at the expected paths.

If the key pair has been lost, create a replacement identity on **inwjud**, then install its public key in the root account's `authorized_keys` on **nizki-demeter**. Never copy the private key to nizki-demeter or GitHub.

### Permission denied (publickey,password)

Test the identity explicitly:

```bash
ssh -i /root/.ssh/demeter_nizki_ed25519 \
  -o IdentitiesOnly=yes \
  root@10.10.110.75
```

Check on the remote server that:

- the correct public key is present in `/root/.ssh/authorized_keys`
- `/root/.ssh` has permission 700
- `/root/.ssh/authorized_keys` has permission 600

Check on inwjud that the private key has permission 600.

For detailed SSH diagnostics:

```bash
ssh -vvv \
  -i /root/.ssh/demeter_nizki_ed25519 \
  -o IdentitiesOnly=yes \
  root@10.10.110.75
```

### Host key mismatch

If `10.10.110.75` was intentionally rebuilt, independently verify that the machine really changed before replacing the stored host key. Never ignore an unexpected host-key change.

## New-chat recovery procedure

At the beginning of a new ChatGPT conversation:

1. Treat `supawatnick/Demeter` as the repository of record.
2. Read this runbook.
3. Remember that ntap-office is connected to the relay machine, not the Demeter dev machine.
4. Run the SSH validation command.
5. Continue only when the remote reports IP `10.10.110.75` and user `root`.
6. Run every Demeter development command through `ssh nizki-demeter ...`.
7. Never fall back to developing on `inwjud` if SSH is broken. Fix SSH first.

## Repository and product

- GitHub repository: `supawatnick/Demeter`
- Product: **Demeter Retirement Planner**
