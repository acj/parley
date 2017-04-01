defmodule Parley.Eval.Gatekeeper do
  @moduledoc """
  Controls access to built-in functions and modules that may allow untrusted
  users to tamper with the host system, shut down the BEAM, and so forth.
  """

  @init_allowed_non_local [
    {Access,       :all},
    {Bitwise,      :all},
    {Dict,         :all},
    {Enum,         :all},
    {HashDict,     :all},
    {HashSet,      :all},
    {Keyword,      :all},
    {List,         :all},
    {ListDict,     :all},
    {Regex,        :all},
    {Set,          :all},
    {Stream,       :all},
    {String,       :all},
    {Integer,      :all},
    {Binary.Chars, [:to_binary]}, # string interpolation
    {Kernel,       [:access]},
    {System,       [:version]},
    {:calendar,    :all},
    {:math,        :all},
    {:os,          [:type, :version]},
    {MyModule,     :all}, # test module used in lessons!!
    {PrivateModule,     :all}
  ]

  @allowed_non_local Enum.into @init_allowed_non_local, Map.new

  # with 0 arity
  @restricted_local [:binding, :is_alive, :make_ref, :node, :self]
  @allowed_local [:&&, :.., :<>, :access, :and, :atom_to_binary, :binary_to_atom,
    :case, :cond, :div, :elem, :if, :in, :insert_elem, :is_range, :is_record,
    :is_regex, :match?, :nil?, :or, :rem, :set_elem, :sigil_B, :sigil_C, :sigil_R,
    :sigil_W, :sigil_b, :sigil_c, :sigil_r, :sigil_w, :to_binary, :to_char_list,
    :unless, :xor, :|>, :||, :!, :!=, :!==, :*, :+, :+, :++, :-, :--, :/, :<, :<=,
    :=, :==, :===, :=~, :>, :>=, :abs, :atom_to_binary, :atom_to_list, :binary_part,
    :binary_to_atom, :binary_to_float, :binary_to_integer, :binary_to_integer,
    :binary_to_term, :bit_size, :bitstring_to_list, :byte_size,
    :float, :float_to_binary, :float_to_list, :hd, :inspect, :integer_to_binary,
    :integer_to_list, :iolist_size, :iolist_to_binary, :is_atom, :is_binary,
    :is_bitstring, :is_boolean, :is_float, :is_function, :is_integer, :is_list,
    :is_number, :is_tuple, :length, :list_to_atom, :list_to_bitstring,
    :list_to_float, :list_to_integer, :list_to_tuple, :max, :min, :not, :round, :size,
    :term_to_binary, :throw, :tl, :trunc, :tuple_size, :tuple_to_list, :fn, :->, :&,
    :__block__, :"{}", :"<<>>", :::, :lc, :inlist, :bc, :inbits, :^, :when, :|,
    :defmodule, :def, :defp, :__aliases__]

  # Check if the AST contains non allowed code, returns false if it does,
  # true otherwise.
  #
  # check modules
  def safe?({{:., _, [module, fun]}, _, args}, funl, config) do
    module = Macro.expand(module, __ENV__)

    case Map.get(@allowed_non_local, module) do
      :all ->
        safe?(args, funl, config)
      lst when is_list(lst) ->
        (fun in lst) and safe?(args, funl, config)
      _ ->
        false
    end
  end

  # check calls to anonymous functions, eg. f.()
  def safe?({{:., _, f_args}, _, args}, funl, config) do
    safe?(f_args, funl, config) and safe?(args, funl, config)
  end

  # used with :fn
  def safe?([do: args], funl, config) do
    safe?(args, funl, config)
  end

  # used with :'->'
  def safe?({left, _, right}, funl, config) when is_list(left) do
    safe?(left, funl, config) and safe?(right, funl, config)
  end

  # limit range size
  def safe?({:.., _, [begin, last]}, _, _) do
    (last - begin) <= 100 and last < 1000
  end

  # don't size and unit in :::
  def safe?({:::, _, [_, opts]}, _, _) do
    do_opts(opts)
  end

  # allow functions inside the module to be called on that module as locals
  def safe?({:defmodule, _, args}, _, config) do
    safe?(args, get_mod_funs(args), config)
  end

  # check functions defined with Kernel.def/2
  def safe?({fun, _, [header, args]}, funl, config) when fun == :def or fun == :defp do
    case header do
      {:when, _, [_|rest]} ->
        safe?(rest, funl, config) and safe?(args, funl, config)
      _ ->
        safe?(args, funl, config)
    end
  end

  # check 0 arity local functions
  def safe?({dot, _, nil}, funl, _) when is_atom(dot) do
    (dot in funl) or (not dot in @restricted_local)
  end

  def safe?({dot, _, args}, funl, config) do
    ((dot in funl) or (dot in @allowed_local)) and safe?(args, funl, config)
  end

  def safe?(lst, funl, config) when is_list(lst) do
    if length(lst) <= 100 do
      Enum.all?(lst, fn(x) -> safe?(x, funl, config) end)
    else
      false
    end
  end

  def safe?(_, _, _) do
    true
  end

  defp do_opts(opt) when is_tuple(opt) do
    case opt do
      {:size, _, _} -> false
      {:unit, _, _} -> false
      _ -> true
    end
  end

  defp do_opts([h|t]) do
    case h do
      {:size, _, _} -> false
      {:unit, _, _} -> false
      _ -> do_opts(t)
    end
  end

  defp do_opts([]), do: true

  # gets the list of defined functions (non-private and private) in a module
  defp get_mod_funs([_, [do: {:__block__, _, funs}]]) do
    get_funs(funs, [])
  end

  defp get_mod_funs([_, [do: fun]]) do
    get_funs([fun], [])
  end

  defp get_mod_funs(_other) do
    false
  end

  defp get_funs([], funs), do: funs

  defp get_funs([{d, _, args} | t], acc) when d == :def or d == :defp do
    case args do
      [{:when, _, [{fun, _, _} | _]} | _] ->
        get_funs(t, [fun | acc])
      [{fun, _, _} | _] ->
        get_funs(t, [fun | acc])
      _ ->
        get_funs(t, acc)
    end
  end

  defp get_funs([_ | t], acc), do: get_funs(t, acc)
end
