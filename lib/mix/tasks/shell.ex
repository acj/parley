defmodule Mix.Tasks.Shell do
  use Mix.Task

  def run(_args) do
    {:ok, _} = Application.ensure_all_started(:parley)

    Parley.CLI.start()
  end
end
