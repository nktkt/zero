# Roadmap

Goal: make every test in the workspace pass on a fresh macOS 15 (Darwin 25) developer machine, then on Linux CI, with a clear story for the Vercel-Sandbox suites.

This roadmap was written from a live audit on `darwin-arm64` (Node 25.1, npm 11.6, pnpm 10.33, clang 17 via Homebrew) on 2026-05-16. **P0 has been implemented and verified in-tree**; the status table below reflects observed (not predicted) outcomes.

---

## Status Snapshot (post-P0, verified locally)

| Suite | Command | Local (darwin-arm64) | Linux CI | Notes |
|---|---|---|---|---|
| Docs registry | `npm run docs:test` | ✅ 8/8 | ✅ | Pure Node, no native deps |
| WASM runtime smoke | `npm run wasm:runtime:smoke` | ✅ | ✅ | WASM byte-format only |
| Agent repair demo | `npm run agent:demo` | ✅ | ✅ | Diagnostics-only |
| ZLS self-test | `npm run zls -- --self-test` | ✅ | ✅ | LSP fixtures |
| Native build | `make -C native/zero-c` | ✅ | ✅ | C11, single-binary |
| Native smoke | `npm run native:smoke` | ✅ (was SIGABRT) | ✅ | Unblocked by P0 |
| Conformance | `npm run conformance:local` | ✅ (was SIGABRT) | ✅ | Unblocked by P0 |
| TS CLI tests | `npm run test:zero` | ✅ 9/9 | ✅ | Unblocked by P0 |
| Native test (host) | `npm run native:test:local` | ✅ | ✅ | Unblocked by P0 |
| Command contracts (host) | `npm run command-contracts:local` | ✅ | ✅ | — |
| Sanitizer smoke | `npm run native:sanitize` | ✅ | ✅ | ASan/UBSan rebuild |
| Extension tests | `npm test -w zero-lang` | ✅ 4/4 | ✅ | Requires `npm install` |
| Conformance (sandbox) | `npm run conformance` | ⚠️ needs token | ✅ | Needs `VERCEL_OIDC_TOKEN` |
| Native test (sandbox) | `npm run native:test` | ⚠️ needs token | ✅ | Needs `VERCEL_OIDC_TOKEN` |
| Command contracts (sandbox) | `npm run command-contracts` | ⚠️ needs token | ✅ | Needs `VERCEL_OIDC_TOKEN` |

**Bottom line:** every test that does not require a cloud credential passes on macOS 15 today, on this branch.

---

## P0 — Fix the macOS 15 LC_UUID blocker — ✅ DONE

**Why:** Starting with Darwin 25 (macOS 15), `dyld` aborts at load time with `missing LC_UUID load command` for any Mach-O image that lacks an `LC_UUID` load command. The pre-P0 `emit_macho64.c` executable emitter wrote 9 load commands (`LC_SEGMENT_64 ×3`, `LC_DYLD_INFO_ONLY`, `LC_LOAD_DYLINKER`, `LC_LOAD_DYLIB`, `LC_MAIN`, `LC_BUILD_VERSION`, `LC_CODE_SIGNATURE`) but never `LC_UUID` (0x1B). That single omission cascaded into failures in `native:smoke`, `conformance:local`, `native:test:local`, and `test:zero`.

**Repro (before fix):**
```bash
make -C native/zero-c
.zero/bin/zero build --emit exe --target darwin-arm64 examples/add.0 --out /tmp/add
/tmp/add
# dyld[…]: missing LC_UUID load command
```

**What was changed** in `native/zero-c/src/emit_macho64.c` (executable emitter only — object files don't need LC_UUID):
1. Added `uuid_cmd_size = 24` to the size constants block.
2. Folded `uuid_cmd_size` into `sizeofcmds`.
3. Bumped `ncmds` from 9 to 10.
4. Emitted an `LC_UUID` load command (cmd `0x1b`, cmdsize 24, 16-byte UUID payload) between `LC_BUILD_VERSION` and `LC_CODE_SIGNATURE` so the signature blob covers the UUID.
5. Computed the UUID deterministically: SHA-256 over `text.data` then `rodata.data`, truncate to 16 bytes, set RFC-4122 version-4 / variant-10 nibbles. Reuses the file's existing `MachOSha256` helpers — no new dependencies.

**Verified outcomes:**
- `otool -l /tmp/add-uuid` shows `LC_UUID  cmdsize 24  uuid 317BEAE9-2B74-4B2B-88EA-EF89F1D4627E`.
- `npm run native:smoke` → `check ok / math works`, exit 0.
- `ZERO_NATIVE_TEST_ALLOW_LOCAL=1 node conformance/run.mjs` → `conformance ok`, exit 0.
- `node --test .zero/test-js/*.test.js` → 9 pass / 0 fail.
- `ZERO_NATIVE_TEST_ALLOW_LOCAL=1 bash scripts/test-native.sh` → `native conformance ok`, exit 0.
- `npm run native:sanitize` → exit 0 (rebuild with ASan/UBSan + smoke passes).

**Follow-up (low priority):** add an explicit `LC_UUID` presence assertion in `conformance/run.mjs`'s `assertMachOArm64Executable` so a regression cannot ship silently.

---

## P1 — Green the local test suite on macOS — ✅ DONE (all verified post-P0)

| Step | Command | Verified result |
|---|---|---|
| P1.2 Conformance (host) | `ZERO_NATIVE_TEST_ALLOW_LOCAL=1 node conformance/run.mjs` | exit 0 — `conformance ok` |
| P1.3 TS CLI tests | `npm run test:zero` | 9 pass / 0 fail |
| P1.4 Native test (host) | `npm run native:test:local` | exit 0 — `native conformance ok` |
| P1.5 Sanitizer | `npm run native:sanitize` | exit 0 |

### P1.1 Bootstrap script — ✅ DONE
Added `scripts/bootstrap.sh` (runs `npm install` + `npm install -w zero-lang` + `make -C native/zero-c`). Added `npm run test:local` as the single local entrypoint. Verified: `./scripts/bootstrap.sh && npm run test:local` exits 0 on darwin-arm64.

---

## P2 — Workspace and extension tests

### P2.1 VS Code extension — ✅ DONE (verified)
`npm test -w zero-lang` → 4 pass / 0 fail (manifest, snippets, keyword highlighting, comment/string/number highlighting).

### P2.2 Docs site build — open
`pnpm --prefix docs-site install && npm run docs:build` not yet run; CI does run it. Should succeed on Node 25, but left as a follow-up to keep the critical path short.

**Acceptance:** `npm run docs:build` exits 0; `docs-site/.next/` (or equivalent) populated.

---

## P3 — Sandbox suites — deferred to CI / out of local scope

Decision: **do not require `VERCEL_OIDC_TOKEN` for local development.** The three sandbox-gated scripts (`conformance`, `native:test`, `command-contracts`) just re-run their `*:local` variants inside a Vercel-managed Linux VM. CI already runs the same local variants directly on `ubuntu-latest`, so the sandbox path is an opt-in convenience for re-validating Linux behavior from a non-Linux box — not a correctness requirement.

What we do instead:
- **Local devs** run `npm run test:local` (added in P1). Zero credentials needed.
- **Linux verification** comes from the existing `build-and-test` job on `ubuntu-latest`.
- **macOS verification** comes from the new `macos-smoke` job (P4).
- The legacy top-level `npm test` (which still calls the sandbox wrappers) is left in place for anyone with a Vercel token who wants to dry-run the sandbox path, but is no longer the recommended local entrypoint.

Anyone who actually wants to run the sandbox suites: `vercel login && vercel link && vercel env pull` (writes `VERCEL_OIDC_TOKEN` into `.env.local`), then `npm run conformance` etc. Not documented in the main README on purpose — it's a niche workflow.

---

## P4 — CI alignment — ✅ DONE

- Ubuntu job (`build-and-test`) already runs all `*:local` variants. Unchanged.
- Added `macos-smoke` job to `.github/workflows/ci.yml` that:
  - boots `macos-15` runner with Node 24
  - builds the native compiler (`make -C native/zero-c`)
  - runs `npm run test:local` (the consolidated local-runnable suite added in P1)
  - explicitly asserts `otool -l … | grep LC_UUID` on a freshly built darwin-arm64 binary and runs it — this turns the LC_UUID fix into a hard CI gate so the regression cannot return silently

This makes macOS 15 a first-class CI target without depending on Vercel Sandbox or any credentials.

---

## P5 — Repo hygiene (½ day)

### P5.1 Add a LICENSE
The upstream repo ships no license. For a public fork this is a real liability. Add `MIT` (or whichever license the maintainer prefers) and reference it from `README.md`.

### P5.2 Tag the fork point
`git tag upstream/v0.1.1 <commit>` so the divergence point is searchable.

### P5.3 Set up branch protection
Require CI green on `main`; require linear history (the repo's release flow assumes it).

---

## Sequencing

```
P0 LC_UUID fix                                 ✅ DONE
P1 local suite green                           ✅ DONE
P1.1 bootstrap.sh + npm run test:local         ✅ DONE
P2.1 extension tests                           ✅ DONE
P2.2 docs build                                open (½ day, low priority)
P3 sandbox suites                              deferred to CI (out of local scope)
P4 CI macos-15 job + LC_UUID gate              ✅ DONE
P5 hygiene (LICENSE, tags, branch protection)  open
```

Nothing on the critical path remains. P2.2 and P5 are housekeeping.

---

## How to verify locally (macOS 15 or Linux)

```bash
git clone <this-repo>
cd zero
./scripts/bootstrap.sh    # npm install + make -C native/zero-c
npm run test:local        # every suite that doesn't need cloud credentials
```

Verified green on `darwin-arm64` (Node 25.1.0, npm 11.6, clang 17). CI re-runs the same `test:local` flow on `macos-15` and the existing per-step sequence on `ubuntu-latest`.

---

## Out of scope

- New language features.
- Replacing Vercel Sandbox with Docker (would simplify P3 but is a bigger project).
- Multi-version Node compatibility (CI pins Node 24; this roadmap only verifies Node 25 locally because that's what's installed).
