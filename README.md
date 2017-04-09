# Parley

[![Build Status](https://travis-ci.org/acj/parley.svg?branch=master)](https://travis-ci.org/acj/parley) [![Coverage Status](https://coveralls.io/repos/github/acj/parley/badge.svg?branch=master)](https://coveralls.io/github/acj/parley?branch=master)

A remote shell for Elixir apps. Parley provides an IEx-like
[REPL](https://en.wikipedia.org/wiki/Read–eval–print_loop) for interacting
with running applications.

The original use case for Parley is interacting with Elixir apps from a web
browser, but it's possible to use it as an IEx replacement in your terminal
as well.

## Installation

The package can be installed by adding `parley` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:parley, "~> 0.1.0"}]
end
```

## Getting Started

To use Parley in your own project, have a look at the `examples` directory.

The CLI example is the simplest possible way to start up Parley and interact
with it. You can start it from the root directory by running `mix shell`. It's
mostly included as a bare-bones starting point for integrating Parley into your own
apps.

For Phoenix-based apps, you'll need a `Channel`, a `Socket`, and at least one `View`
to expose Parley to browser clients. The `phoenix_shell` example includes a
working implementation to get you started:

```
$ cd examples/phoenix_shell
$ mix phoenix.server
[info] Running PhoenixShell.Endpoint with Cowboy using http://localhost:4000
```

Browse to http://localhost:4000, and you should be able to type Elixir commands.

## Credits

Parley is loosely based on [Try-Elixir](https://github.com/acj/Try-Elixir), a
handy tool for playing with the Elixir language in your browser.

## License

MIT. See the `LICENSE` file for the nitty gritty.
