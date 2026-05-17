# Changelog

## Unreleased (nktkt fork)

This fork (https://github.com/nktkt/zero) adds the following on top of upstream `vercel-labs/zero` 0.1.1.

### Compiler (darwin-arm64 direct Mach-O backend)

- **`LC_UUID` load command** is now emitted in executables. Required by Darwin 25 (macOS 15) dyld, which aborts at load time on Mach-O images that lack it. UUID is derived deterministically from SHA-256 of the `__text` + `__const` bytes, with RFC 4122 v4/variant bits set.
- **`UDIV` / `MSUB` lowering** added so `/` and `%` work for `u32`. Previously failed with `CGEN004: direct AArch64 Mach-O binary operator is unsupported`.
- **`AND` / `ORR` lowering** added so `&&` and `||` work on `Bool`. Non-short-circuit (bitwise) semantics matching the existing elf64 backend.
- **Silent-wrong-answer fix for `&&`/`||` chains** whose operands are comparisons. `IR_VALUE_COMPARE` hard-codes `W8`/`W9` as its scratch and clobbered the lhs that `IR_VALUE_BINARY` had parked there. Logical-op operands now stage in `W12`/`W13`; arithmetic ops keep `W8`/`W9` to preserve the `direct-call-add` byte conformance.

### Parser

- **Unary `!` and unary `-`** now parse. Implemented by parse-time desugaring (`!x` → `x == false`, `-x` → `0 - x`), zero IR or backend changes required. Negative integer literals (`let x: i32 = -5`) work.

### Conformance

- New runtime fixtures: `divmod.0`, `logic-ops.0`, `unary-ops.0`, `mixed-and-chain.0`. Each builds on both darwin-arm64 and linux-musl-x64 and asserts a stdout golden, so any future regression on either backend trips `npm run conformance:local`.

### CI / repo hygiene

- New `macos-smoke` job on `macos-15` runs `npm run test:local` plus an `otool -l | grep LC_UUID` gate and a fizzbuzz stdout golden. Locks the macOS-only fixes against silent regression.
- Top-level `npm run test:local` runs every locally-runnable suite without requiring a Vercel Sandbox / `VERCEL_OIDC_TOKEN`.
- `scripts/bootstrap.sh` handles `npm install` + `make -C native/zero-c` for a one-command first-clone setup.
- `.github/workflows/ci.yml` opts JS-based actions into Node 24 and bumps `actions/checkout` / `actions/setup-node` to `@v6` (Node 24 native).
- `.github/dependabot.yml` configured for weekly npm, pnpm (docs-site), and github-actions updates; vulnerability alerts and security PRs enabled at the repo level.
- Branch protection on `main`: both CI jobs required, linear history, no force-push, no deletion.
- MIT `LICENSE` added (upstream shipped without one).

### Example programs

- `examples/launch.0` — minimal countdown demo that runs on the direct backend.
- `examples/fizzbuzz.0` — uses `/`, `%`, and the new operator support end-to-end.

## 0.1.1

<!-- release:start -->

- Adds the public installer at `https://zerolang.ai/install.sh`, with platform selection, GitHub release downloads, checksum verification, and `$HOME/.zero/bin/zero` installation.
- Adds `zero run` for the everyday edit loop: build a host executable, run it, pass program arguments after `--`, forward stdout/stderr, and return the program exit status.
- Updates README, homepage, getting started, install, and CLI docs around the curl install path, copyable commands, and `zero run`.
- Reworks public docs to be more scannable and current, including stronger language, diagnostics, testing, target, package, optimization, and standard library references.
- Removes placeholder module docs that described surfaces not ready for users and adds current module docs for `std.crypto`, `std.http`, and `std.net`.
- Adds version-matched agent guidance through `zero skills`, including focused workflows for Zero syntax, diagnostics, builds, packages, standard library use, testing, and agent edit loops.
- Keeps the installable Zero skill as a thin bootstrap so external skill managers discover one Zero skill while the compiler serves the richer guidance for the installed version.
- Updates the `zero skills` CLI contract to serve bundled flat skill data while preserving list, get, path, and JSON workflows.

### Contributors

- @ctate
- @mvanhorn

<!-- release:end -->

## 0.1.0

- Initial public release of Zero as the programming language for agents.
- Includes the native compiler, examples, documentation site, and validation fixtures.
- Supported workflows use direct Zero emitters for the documented examples and targets.
