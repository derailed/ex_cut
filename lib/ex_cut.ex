defmodule ExCut do
  @moduledoc """
  ExCut defines an annotation construct that wraps a regular function and enable
  it to be decorated with a cross-cutting concern. This provide a clean mechanism
  to inject resusable behavior without cluttering your code base.

  Let's take a look at ExCut in action to add logging behavior to a set of
  functions.

  ```elixir
  defmodule Blee do
    use ExCut, marker: :log, pre: :pre_log, post: :post_log
    require Logger

    # Basic annotation setting a log level
    @log level: :info
    def elvis(a, b), do: a + b

    # You can also override module pre or post within an annotation
    @log level: :debug, pre: :cust_pre_log
    def elvis(a, b) when is_binary(a), do: a <> b

    @log level: :warm
    def elvis(a, b) when is_boolean(a), do: b

    defp pre_log(ctx) do
      msg = ">>> \#{ctx.target} with args \#{ctx.args |> inspect}"
      case ctx.meta[:level] do
        :info  -> Logger.info  msg
        :debug -> Logger.debug msg
      end
    end

    defp post_log(_ctx, _pre, _res) do
      msg = "<<< \#{ctx.target} with args \#{ctx.args |> inspect}"
      case ctx.meta[:level] do
        :info  -> Logger.info  msg
        :debug -> Logger.debug msg
      end
    end

    defp cust_pre_log(ctx) do
      msg = "[CUSTOM!] >>> \#{ctx.target} with args \#{ctx.args |> inspect}"
      case ctx.meta[:level] do
        :info  -> Logger.info  msg
        :debug -> Logger.debug msg
      end
    end
  end
  ```

  ExCut provisions an `ExCut.Context` with call details and metadata
  that comes from the annotation. You can leverage this information in
  your cross-cutting functions.
  """

  @doc """
  Defines an annotation to enable cross-cutting concerns to be injected
  before the function is called and after the function exits. This macro
  defines a new function that overrides the original function and decorates
  the call. The annotated function is generated at compile time.
  """
  defmacro __using__(opts) do
    marker = opts[:marker]
    quote do
      import ExCut

      __MODULE__ |> Module.put_attribute(:ex_cut_opts, unquote(opts))
      __MODULE__ |> Module.register_attribute(unquote(marker), accumulate: true)
      __MODULE__ |> Module.register_attribute(:ex_cut_funs, accumulate: true)

      @on_definition  {ExCut, :on_definition}
      @before_compile {ExCut, :before_compile}
    end
  end

  @doc """
  Flags functions that have been annotated for further processing during
  the compilation phase
  """
  def on_definition(env, k, f, a, g, b) do
    opts = env.module |> Module.get_attribute(:ex_cut_opts)
    meta = env.module |> Module.get_attribute(opts[:marker]) |> List.first || []

    if opts[:enabled] == false do
      :ok
    else
      if meta |> Enum.empty? do
        case env |> annotated?(k, f, a, g, b) do
          nil -> :ok
          _   -> env.module |> Module.put_attribute(:ex_cut_funs, {k, f, a, g, b, nil})
        end
      else
        env.module |> Module.put_attribute(:ex_cut_funs, {k, f, a, g, b, meta})
        env.module |> Module.delete_attribute(opts[:marker])
      end
    end
  end

  defp annotated?(env, _, fun, arg, _, _) do
    env.module
    |> Module.get_attribute(:ex_cut_funs)
    |> Enum.find(fn({_, f, a, _, _, _}) -> ({fun, length(arg)} == {f, length(a)})
    end)
  end

  @doc """
  Generates a new cross-cutting function with optional before and after hooks
  that calls the original function. Pre and Post hooks can be defined at the
  module level or overriden on a per function basis.
  """
  defmacro before_compile(env) do
    funs = env.module |> Module.get_attribute(:ex_cut_funs)
    env.module |> Module.delete_attribute(:ex_cut_funs)

    overrides = funs
    |> Enum.reduce({nil, 0, []}, fn(f, acc) -> gen_override(env, f, acc) end)
    |> elem(2)

    funcs = funs
    |> Enum.reduce([], fn(f, acc) -> gen_func(env, f, acc) end)
    |> Enum.reverse

    overrides ++ funcs
  end

  defp gen_override(_e, {_kind, f, a, _g, _, _m}, {prev_fun, arity, acc}) do
    def_override = quote do
      defoverridable [{unquote(f), unquote(length(a))}]
    end

    if f == prev_fun and length(a) == arity do
      {f, length(a), acc}
    else
      {f, length(a), acc ++ [def_override]}
    end
  end

  defp gen_func(env, {_kind, f, a, g, _, meta}, acc) do
    def_body = gen_body(env, {f, a, g}, meta)

    params = a |> ExCut.Args.expand

    def_func = g
    |> case do
      [] ->
        quote do
          def unquote(f)(unquote_splicing(params)) do
            unquote(def_body)
          end
        end
      _  ->
        quote do
          def unquote(f)(unquote_splicing(params)) when unquote_splicing(g) do
            unquote(def_body)
          end
        end
    end
    acc ++ [def_func]
  end

  defp expand_args(args) do
    args
    |> ExCut.Args.expand
    |> Enum.map(fn
      ({:\\, _, [a, _]}) -> a
      (arg)              -> arg
    end)
  end

  defp gen_context({f, _a, g}, params, meta) do
    quote do
      ctx = %ExCut.Context{
        target: unquote(f),
        args:   unquote(params),
        guards: unquote(g),
        meta:   unquote(meta)
      }
    end
  end

  defp gen_body(env, {_f, args, _g}=sig, meta) do
    opts   = env.module |> Module.get_attribute(:ex_cut_opts)
    params = args |> expand_args
    ctx    = gen_context(sig, params, meta)

    if meta == nil do
      quote do
        super(unquote_splicing(params))
      end
    else
      meta
      |> is_list
      |> case do
        true  -> {
          meta |> Keyword.get(:pre, opts[:pre]),
          meta |> Keyword.get(:post, opts[:post])
        }
        false -> {opts[:pre], opts[:post]}
      end
      |> gen_body(params, ctx)
    end
  end

  defp gen_body({nil, nil}, params, _ctx) do
    quote do
      super(unquote_splicing(params))
    end
  end

  defp gen_body({pre, nil}, params, ctx) do
    quote do
      unquote(ctx)
      unquote(pre)(ctx)
      super(unquote_splicing(params))
    end
  end

  defp gen_body({nil, post}, params, ctx) do
    quote do
      unquote(ctx)
      try do
        super(unquote_splicing(params))
      rescue
        err -> unquote(post)(ctx, nil, err)
              throw err
      else
        res -> unquote(post)(ctx, nil, res)
        res
      end
    end
  end

  defp gen_body({pre, post}, params, ctx) do
    quote do
      unquote(ctx)

      pre = unquote(pre)(ctx)
      try do
        super(unquote_splicing(params))
      rescue
        err -> unquote(post)(ctx, pre, err)
               throw err
      else
        res -> unquote(post)(ctx, pre, res)
               res
      end
    end
  end
end
