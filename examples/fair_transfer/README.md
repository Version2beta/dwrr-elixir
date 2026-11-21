# Fair file-transfer simulation

A standalone Mix project using this checkout through `{:dwrr, path: "../.."}`.
Requires Elixir >= 1.18 and OTP >= 27. No external dependencies, network access,
real files/transfers, sleeps, processes owned by the example, or database.

From the repository root, run offline:

```sh
cd examples/fair_transfer
mix compile --warnings-as-errors
mix fair_transfer
mix test --warnings-as-errors
mix format --check-formatted
```

No `mix deps.get` is needed: the dependency is already present locally. Dwrr's
own test-only StreamData dependency is not needed by this project. Builds remain
under this example's ignored `_build/`; do not change the root Mix configuration,
dependencies or lockfile. Tests here are separate from the root test suite.

## What it does

Three customers have separate FIFO queues:

| Customer | Quantum (declared bytes per visit) |
| --- | ---: |
| Basic | 1024 |
| Team | 2048 |
| Business | 4096 |

`FairTransfer.demo/0` supplies twelve variable-size pretend transfer records.
`FairTransfer.run/1` is pure: it accepts a finite list of maps with `:id`, a known
`:customer` (`:basic`, `:team`, `:business`), and positive integer `:bytes` within
Dwrr's cost limit. It enqueues each record as
`%Dwrr.Item{cost: transfer.bytes, value: transfer}`, repeatedly calls
`Dwrr.take(scheduler, 1)` until empty, and returns a service trace. Each entry has
`:transfer`, the selected `:bytes`, and cumulative `:totals` for all customers.
Inputs retain their order within each customer, even if interleaved in the list.
This is a small example for valid inputs, not an input-validation service.

The Mix task only prints that trace; it does not send anything. For example:

```text
Pretend transfers (quanta: Basic=1024 Team=2048 Business=4096 bytes)
basic-1: 512 bytes | cumulative bytes: Basic=512 Team=0 Business=0
team-1: 1024 bytes | cumulative bytes: Basic=512 Team=1024 Business=0
business-1: 2048 bytes | cumulative bytes: Basic=512 Team=1024 Business=2048
...
basic-4: 2304 bytes | cumulative bytes: Basic=5120 Team=6656 Business=8704
```

## Fairness and boundaries

Fairness is by **declared bytes**, not number of transfers or elapsed time.
While queues stay backlogged, their quanta weight the service they receive;
item sizes and visit boundaries cause short-term variation. A head larger than
its current credit waits for later grants; smaller transfers behind it cannot
jump ahead. Repeated single-item takes preserve a paused visit, rather than
awarding fresh credit on every call.

Each selected transfer is whole and nonpreemptive. A real sender that sends a
large file all at once can delay other customers regardless of scheduling.
Use bounded chunks as scheduler items in a real sender, and account for their
actual byte costs. This scheduler does **not** limit bandwidth, pace sends, or
model transfer duration, concurrency, retries or failures.

All queues eventually drain in this finite demonstration. Final totals reflect
only the offered data, **not guaranteed fairness percentages** or a required
1:2:4 ratio. There is no timing or throughput claim.
