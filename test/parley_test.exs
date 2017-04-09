defmodule ParleyTest do
  alias Parley.Eval
  use ExUnit.Case
  doctest Parley

  @restricted_error "** (RuntimeError) restricted"

  setup_all do
    {:ok, unsafe_eval} = Parley.Eval.start_link(allow_unsafe_commands: true)
    {:ok, safe_eval} = Parley.Eval.start_link(allow_unsafe_commands: false)

    {:ok, [safe_eval: safe_eval, unsafe_eval: unsafe_eval]}
  end

  describe "allow_unsafe_commands: false" do
    test "Sanity check", context do
      assert {_, {:ok, 2}} = Eval.evaluate(context[:safe_eval], "1 + 1")
    end

    test "Enum with capture function is allowed", context do
      assert {_, {:ok, [2, 4, 6]}} = Eval.evaluate(context[:safe_eval], "Enum.map([1, 2, 3], &(&1 * 2))")
    end

    test "Enum with function is allowed", context do
      assert {_, {:ok, [2, 3, 4]}} = Eval.evaluate(context[:safe_eval], "Enum.map([1, 2, 3], fn(x) -> x + 1 end)")
    end

    test "IO module is restricted", context do
      assert {_, {:error, @restricted_error}} = Eval.evaluate(context[:safe_eval], "IO.puts \"Hello world!\"")
    end

    test "System module is restricted", context do
      assert {_, {:error, @restricted_error}} = Eval.evaluate(context[:safe_eval], "fn -> System.cmd(\"pwd\") end")
    end

    test "Bare function is allowed", context do
      Eval.evaluate(context[:safe_eval], "square = fn(x) -> x * x end")
      assert {_, {:ok, 25}} = Eval.evaluate(context[:safe_eval], "square.(5)")
    end

    test "self function is restricted", context do
      assert {_, {:error, @restricted_error}} = Eval.evaluate(context[:safe_eval], "self()")
    end

    test "ls is restricted", context do
      assert {_, {:error, @restricted_error}} = Eval.evaluate(context[:safe_eval], "ls(\".\")")
    end

    test "spawn is restricted", context do
      assert {_, {:error, @restricted_error}} = Eval.evaluate(context[:safe_eval], "spawn(fn -> 1 + 1 end)")
    end

    test "Access protocol", context do
      Eval.evaluate(context[:safe_eval], "foo = [a: 1, b: 2, c: 3]")
      assert {_, {:ok, 2}} = Eval.evaluate(context[:safe_eval], "foo[:b]")
    end
  end

  describe "allow_unsafe_commands: true" do
    test "Process module", context do
      assert {_, {:ok, processes}} = Eval.evaluate(context[:unsafe_eval], "Process.list")
      assert is_list(processes)
      assert Enum.all?(processes, &(is_pid/1))
    end

    test "self function", context do
      assert {_, {:ok, pid}} = Eval.evaluate(context[:unsafe_eval], "self()")
      assert is_pid(pid)
    end

    test "System module", context do
      assert {_, {:ok, {"", 0}}} = Eval.evaluate(context[:unsafe_eval], "(fn -> System.cmd(\"true\", []) end).()")
    end
  end
end
