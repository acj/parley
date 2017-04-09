defmodule Parley.ShellChannel do
  require Logger
  use Phoenix.Channel

  def join("shell", _message, socket) do
    Logger.debug "JOIN #{socket.channel}.#{socket.topic}"
    {:ok, %{identifier: socket.assigns[:client_id], status: "REMOTE IEX TERMINAL READY", version: System.version()}, socket}
  end

  def join("shell:" <> shell_identifier, _message, socket) do
    if validate_client(socket, shell_identifier) do
      Parley.ShellServer.start(shell_identifier)
      Logger.debug "JOIN #{socket.channel}.#{socket.topic}"
      {:ok, %{status: "REMOTE IEX TERMINAL READY", version: System.version()}, socket}
    else
      Logger.warn "JOIN unauthorized for #{shell_identifier}"
      unauthorized_response()
    end
  end

  def join(unknown_topic, _message, _socket) do
    Logger.warn "JOIN unauthorized for unrecognized topic: #{unknown_topic}"
    unauthorized_response()
  end

  def handle_in("shell:" <> shell_identifier, message, socket) do
    if validate_client(socket, shell_identifier) do
      eval_result = Parley.ShellServer.eval(shell_identifier, message["data"])
      response = format_json(eval_result)
      {:reply, {:ok, %{command_result: response}}, socket}
    else
      Logger.warn "Message unauthorized: #{message}"
      unauthorized_response()
    end
  end

  defp validate_client(socket, candidate_id) do
    socket.assigns[:client_id] == candidate_id
  end

  defp unauthorized_response do
    {:error, %{reason: :unauthorized}}
  end

  defp format_json({prompt, nil}) do
    ~s/{"prompt":"#{prompt}"}/
  end

  defp format_json({prompt, {"error", result}}) do
    result = Inspect.BitString.escape(result, ?")
    ~s/{"prompt":"#{prompt}","type":"error","result":"#{result}"}/
  end

  defp format_json({prompt, {type, result}}) do
    # show double-quotes in strings
    result = Inspect.BitString.escape(inspect(result), ?")
    ~s/{"prompt":"#{prompt}","type":"#{type}","result":"#{result}"}/
  end
end
