# Zero

Zero is a programming language for agents — a systems language focused on small native tools, explicit effects, predictable memory, and structured compiler output.

This repository is an independent project based on the original work from [vercel-labs/zero](https://github.com/vercel-labs/zero).

> **Status:** Experimental. The compiler, standard library, docs, and examples are useful for trying the language out, but the language is not yet stable.

## Quick Start

Install the latest upstream release:

```bash
curl -fsSL https://zerolang.ai/install.sh | bash
export PATH="$HOME/.zero/bin:$PATH"
zero --version
```

Check a program:

```bash
zero check examples/hello.0
```

Run a small executable:

```bash
zero run examples/add.0
```

Expected output:

```text
math works
```

## Learn Zero

- `docs-site/articles/getting-started.md` — build the compiler and run a first program.
- `docs-site/articles/learn-zero.md` — a practical tour of the language.
- `docs-site/articles/language-reference.md` — syntax and behavior reference.
- `examples/README.md` — examples grouped by concept.

Run the docs site locally:

```bash
npm run docs:dev
```

## Common Commands

```bash
zero check examples/hello.0
zero run examples/add.0
zero build --emit exe --target linux-musl-x64 examples/add.0 --out .zero/out/add
zero graph --json examples/systems-package
zero size --json examples/point.0
zero routes --json examples/web/hello
zero skills get zero --full
zero doctor --json
```

## Validation

For local development (no cloud credentials required):

```bash
./scripts/bootstrap.sh    # npm install + build native compiler
npm run test:local        # full local-runnable test suite
```

Individual suites:

```bash
npm run docs:test
npm run conformance:local
npm run native:test:local
npm run command-contracts:local
```

The bare `npm run conformance` / `native:test` / `command-contracts` variants wrap their `*:local` counterparts in a Vercel Sandbox VM and require a `VERCEL_OIDC_TOKEN`. CI runs the local variants directly on Linux and macOS, so the sandbox path is opt-in.

Benchmarks run locally by default:

```bash
npm run bench:local
```

## Repository Layout

- `native/zero-c/` — native compiler implementation.
- `compiler-zero/` — Zero-authored compiler sources.
- `examples/` — runnable Zero source examples.
- `conformance/` — language and CLI behavior fixtures.
- `docs-site/` — documentation site.
- `tests/` — TypeScript tests for CLI behavior.
- `extensions/vscode/` — editor syntax highlighting for `.0` files.

## License

Released under the [MIT License](./LICENSE).

## Credits

The original Zero language and toolchain were developed at [vercel-labs/zero](https://github.com/vercel-labs/zero).
