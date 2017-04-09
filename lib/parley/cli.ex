defmodule Parley.CLI do
  @moduledoc """
  A simple IEx-like command interpreter built on Parley
  """

  alias Parley.ShellServer

  def start do
    shell_identifier = "MyShellIdentifier"
    {:ok, _} = Parley.ShellServer.start(shell_identifier, allow_unsafe_commands: true)

    do_command_loop(shell_identifier, "parley(1)> ")
  end

  defp do_command_loop(server, prompt) do
    command = IO.gets(prompt)

    {new_prompt, {result_type, eval_result}} = ShellServer.eval(server, command)

    case result_type do
      :ok -> Mix.shell.info "#{inspect eval_result}"
      :error -> Mix.shell.error "#{inspect eval_result}"
    end

    do_command_loop(server, new_prompt)
  end
end
