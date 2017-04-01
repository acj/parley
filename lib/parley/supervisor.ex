defmodule Parley.Supervisor do
  import Supervisor.Spec
  require Logger
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Parley.ShellServer, [], restart: :transient)
    ]

    # See http://elixir-lang.org/docs/stable/Supervisor.Behaviour.html
    # for other strategies and supported options
    supervise(children, strategy: :simple_one_for_one)
  end

  def start_child(id) do
    Logger.debug("Starting Parley shell with identifier #{inspect id}")
    {:ok, _} = Supervisor.start_child(__MODULE__, [%{name: Parley.ShellServer.via(id), identifier: id}])
  end
end
