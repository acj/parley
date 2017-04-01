defmodule Parley do
  require Logger
  use Application

  def start(_type, _args) do
    Logger.debug("Starting Parley")
    import Supervisor.Spec

    children = [
      supervisor(Registry, [:unique, Parley.Registry]),
      supervisor(Parley.Supervisor, []),
    ]

    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
