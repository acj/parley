defmodule Parley.ShellServer do
  alias Parley.Eval
  use GenServer
  require Logger

  @timeout 300_000

  def start(id) do
    {:ok, _} = Parley.Supervisor.start_child(id)
  end

  def start_link(config) do
    Logger.debug("Starting #{__MODULE__} with ID #{config[:identifier]} timeout #{@timeout}")
    GenServer.start_link(__MODULE__, config, name: config[:name])
  end

  def via(id) do
    {:via, Registry, {Parley.Registry, "ShellServer_#{id}"}}
  end

  def eval(shell_identifier, command) do
    GenServer.call(via(shell_identifier), {:eval, command})
  end

  def init(config) do
    {:ok, evaluator} = Parley.Eval.start_link(allow_unsafe_commands: false)
    state = %{identifier: config[:identifier], evaluator: evaluator}
    {:ok, state, @timeout}
  end

  def handle_info(:timeout, state) do
		Logger.info("#{__MODULE__} shutting down due to timeout")

    # TODO: Send message in channel

    {:stop, :normal, state}
	end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_call({:eval, command}, _from, state) do
    Logger.debug "[command](#{state[:identifier]}) #{command}"
    response = Eval.evaluate(state[:evaluator], command)
    Logger.debug "[response](#{state[:identifier]}) #{inspect response}"

    {:reply, response, state, @timeout}
  end
end
