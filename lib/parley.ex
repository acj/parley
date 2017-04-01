defmodule Parley do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Registry, [:unique, Parley.Registry]),
      supervisor(Parley.Supervisor, []),
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
