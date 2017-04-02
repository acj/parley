# Parley

[![Build Status](https://travis-ci.org/acj/parley.svg?branch=master)](https://travis-ci.org/acj/parley) [![Coverage Status](https://coveralls.io/repos/github/acj/parley/badge.svg?branch=master)](https://coveralls.io/github/acj/parley?branch=master)

A web-based remote shell for Elixir apps. Parley provides an IEx-like
[REPL](https://en.wikipedia.org/wiki/Read–eval–print_loop) for running
applications. It uses websockets for transport and can be used from any
browser.

## Installation

The package can be installed by adding `parley` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:parley, "~> 0.1.0"}]
end
```

## License

MIT. See the `LICENSE` file for the nitty gritty.
