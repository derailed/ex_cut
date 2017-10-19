defmodule XCut do
  @moduledoc false

  # Doc!
  # X BOZO handle guards
  # BOZO Pattern match test
  # X BOZO private functions ??
  # BOZO Switch to context
  # BOZO Call craps out!
  # Make pre and post optional

  defmacro __using__(opts) do
    quote do
      import XCut

      __MODULE__ |> Module.put_attribute(:xcut_opts, unquote(opts))

      __MODULE__ |> Module.register_attribute(unquote(opts[:marker]), accumulate: true)
      __MODULE__ |> Module.register_attribute(:xcut_funs, accumulate: true)

      @on_definition  {XCut, :on_definition}
      @before_compile {XCut, :before_compile}
    end
  end

  def on_definition(env, kind, fun, args, guards, body) do
    opts = env.module |> Module.get_attribute(:xcut_opts)
    meta = env.module |> Module.get_attribute(opts[:marker])
    unless (meta |> Enum.empty?) do
      env.module |> Module.put_attribute(:xcut_funs, {kind, fun, args, guards, body, meta})
    end
    env.module |> Module.delete_attribute(opts[:marker])
  end

  defmacro before_compile(env) do
    funs = env.module |> Module.get_attribute(:xcut_funs)
    env.module |> Module.delete_attribute(:xcut_funs)
    funs
    |> Enum.reduce({nil, 0, []}, fn(f, acc) -> generate(env, f, acc) end)
    |> elem(2)
  end

  def generate(env, {_kind, fun, args, guard, _body, meta}, {prev_fun, arity, acc}) do
    opts = env.module |> Module.get_attribute(:xcut_opts)

    {pre, post} = meta
    |> List.first
    |> is_list
    |> case do
      true  -> {meta |> List.first |> Keyword.get(:pre), meta |> List.first |> Keyword.get(:post)}
      false -> {opts[:pre], opts[:post]}
    end

    vals = args |> Enum.map(fn({:\\, _, [a, _]}) -> a; (arg) -> arg end)

    def_body = quote do
      init = unquote(pre)([fun: {unquote(fun), unquote(vals), unquote(guard)}, meta: unquote(meta)])
      res = super(unquote_splicing(vals))
      unquote(post)([fun: {unquote(fun), unquote(vals), unquote(guard)}, meta: unquote(meta)], init)
      res
    end

    def_override = quote do
      defoverridable [{unquote(fun), unquote(length(args))}]
    end

    def_func = guard
    |> case do
    [] ->
      quote do
        def unquote(fun)(unquote_splicing(args)) do
          unquote(def_body)
        end
      end
    _  ->
      quote do
        def unquote(fun)(unquote_splicing(args)) when unquote_splicing(guard) do
          unquote(def_body)
        end
      end
    end

    if fun == prev_fun and length(args) == arity do
      {fun, length(args), acc ++ [def_func]}
    else
      {fun, length(args), acc ++ [def_override, def_func]}
    end
  end
end
