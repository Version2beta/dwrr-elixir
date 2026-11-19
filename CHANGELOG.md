# CHANGELOG

## 0.1.0 (unreleased)

Initial Elixir release of `dwrr`. It is not yet published to Hex or HexDocs, and
no release date has been set.

### Added

- `Dwrr`: a pure, immutable deficit weighted round robin (DWRR) scheduler. Each
  operation returns a new value. No process or I/O is involved.
- `Dwrr.Server`: an optional GenServer wrapper that keeps one immutable scheduler
  in one caller-supervised process. Calls use default timeouts. A restarted server
  starts fresh, and state is not persisted.
- Behavior follows the shared dwrr specification draft 0.1.1 (SPEC and PROTOCOL),
  checked against the pinned conformance corpus.

### Notes

- This is the initial Elixir release. It does not copy the Go repository's
  history, and it does not invent a publication date.
- See [TESTING.md](TESTING.md) for the test suite, property tests and pinned
  external conformance tools.
