defmodule Parley.Eval do
  use GenServer
  require Logger

  def start_link(opts) do
		GenServer.start_link(__MODULE__, opts)
	end

  def init(opts) do
		Logger.info "Starting #{__MODULE__}"

    env    = :elixir.env_for_eval(file: "iex", delegate_locals_to: nil)
    scope  = :elixir_env.env_to_scope(env)
    unsafe = opts[:allow_unsafe_commands] || false
    state  = %{
      counter: 1,
      binding: [],
      cache: '',
      scope: scope,
      env: env,
      result: nil,
      allow_unsafe_commands: unsafe
    }
		{:ok, state}
	end

  def handle_info(_msg, proc) do
    {:noreply, proc}
  end

  def handle_call({:evaluate, command}, _from, state) do
    {prompt, state} = evaluate_command(command, state)

    result = {prompt, state[:result]}
    state = %{state | result: nil}

    {:reply, result, state}
  end

  def evaluate(pid, command) when is_pid(pid) and is_binary(command) do
    GenServer.call(pid, {:evaluate, command})
  end

  defp evaluate_command(command, state) do
    new_state =
      try do
        counter = state[:counter]
        code    = state[:cache]
        eval(code, :unicode.characters_to_list(command), counter, state)
      catch
        kind, error ->
          Logger.debug("Error raised while evaluating command: #{command}")
          Logger.debug("Stack trace: #{inspect System.stacktrace}")

          %{state | cache: '', result: {"error", format_error(kind, error, System.stacktrace)}}
      end

    {new_prompt(new_state), new_state}
  end

  defp format_error(kind, reason, stacktrace) do
    {reason, stacktrace} = normalize_exception(kind, reason, stacktrace)
    Exception.format_banner(kind, reason, stacktrace)
  end

  defp normalize_exception(:error, :undef, [{IEx.Helpers, fun, arity, _}|t]) do
    {%RuntimeError{message: "undefined function: #{format_function(fun, arity)}"}, t}
  end

  defp normalize_exception(_kind, reason, stacktrace) do
    {reason, stacktrace}
  end

  defp format_function(fun, arity) do
    cond do
      is_list(arity) ->
        "#{fun}/#{length(arity)}"
      true ->
        "#{fun}/#{arity}"
    end
  end

  defp new_prompt(state) do
    prefix = if state[:cache] != '', do: "..."
    "#{prefix || "iex"}(#{state[:counter]})> "
  end

  # The expression is parsed to see if it's well formed.
  # If parsing succeeds the AST is checked to see if the code is allowed,
  # if it is, the AST is evaluated.
  #
  # If parsing fails, this might be a TokenMissingError which we treat in
  # a special way (to allow for continuation of an expression on the next
  # line in the `eval_loop`). In case of any other error, we let :elixir_translator
  # to re-raise it.
  #
  # Returns updated state.
  defp eval(code_so_far, latest_input, line, state) do
    code = code_so_far ++ latest_input
    case Code.string_to_quoted(code, [line: line, file: "iex"]) do
      { :ok, forms } ->
        unless state[:allow_unsafe_commands] || __MODULE__.Gatekeeper.safe?(forms, [], state) do
          raise "restricted"
        end

        {result, new_binding, env, scope} = :elixir.eval_forms(forms, state[:binding], state[:env], state[:scope])

        %{state | env: env,
           cache: '',
           scope: scope,
           binding: new_binding,
           counter: state[:counter] + 1,
           result: {"ok", result}}

      { :error, { line, error, token } } ->
        if token == [] do
          # Update state[:cache] in order to keep adding new input to
          # the unfinished expression in `code`
          %{state | cache: code ++ '\n'}
        else
          # Encountered malformed expression
          :elixir_errors.parse_error(line, "iex", error, token)
        end
    end
  end
end
