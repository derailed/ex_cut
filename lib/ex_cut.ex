defmodule ExCut do
  @moduledoc """
  ExCut defines an annotation construct that wraps a regular function and enable
  it to be decorated with a cross-cutting concern. This provide a nice mechanism
  to inject resusable behavior without cluttering your code base.

  Let's take a look at ExCut in action to add logging behavior to a set of
  functions.

  ```elixir
  defmodule Blee do
    use ExCut, marker: :log, pre: :pre_log, post: :post_log

    @log level: :info
    def elvis(a, b), do: a + b

    @log level: :debug
    def elvis(a, b) when is_binary(a), do: a <> b

    defp pre_log(ctx) do
      msg = ">>> \#{ctx.target} with args \#{ctx.args |> inspect}"
      case ctx.meta[:level] do
        :info  -> Logger.info  msg
        :debug -> Logger.debug msg
      end
    end

    defp post_fun(_ctx, span, _res) do
      msg = <<< \#{ctx.target} with args \#{ctx.args |> inspect}"
      case ctx.meta[:level] do
        :info  -> Logger.info  msg
        :debug -> Logger.debug msg
      end
    end
  end
  ```

  ExCut provisions an `ExCut.Context` with function details and metadata
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
    meta = env.module |> Module.get_attribute(opts[:marker])
    unless meta |> Enum.empty? do
      env.module |> Module.put_attribute(:ex_cut_funs, {k, f, a, g, b, meta})
    end
    env.module |> Module.delete_attribute(opts[:marker])
  end

  @doc """
  Generates a new cross-cutting function with optional before and after hooks
  that calls the original function. Pre and Post hooks can be defined at the
  module level or overriden on a per function basis.
  """
  defmacro before_compile(env) do
    funs = env.module |> Module.get_attribute(:ex_cut_funs)
    env.module |> Module.delete_attribute(:ex_cut_funs)
    funs
    |> Enum.reduce({nil, 0, []}, fn(f, acc) -> generate(env, f, acc) end)
    |> elem(2)
  end

  defp generate(env, {_kind, f, a, g, _, meta}, {prev_fun, arity, acc}) do
    def_body = gen_body(env, {f, a, g}, meta)

    def_override = quote do
      defoverridable [{unquote(f), unquote(length(a))}]
    end

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

    if f == prev_fun and length(a) == arity do
      {f, length(a), acc ++ [def_func]}
    else
      {f, length(a), acc ++ [def_override, def_func]}
    end
  end

  defp gen_body(env, {fun, args, guard}, meta) do
    opts = env.module |> Module.get_attribute(:ex_cut_opts)

    params = args
    |> ExCut.Args.expand
    |> Enum.map(fn
      ({:\\, _, [a, _]}) -> a
      (arg)              -> arg
    end)

    ctx = quote do
      ctx = %ExCut.Context{
        target: unquote(fun),
        args:   unquote(params),
        guards: unquote(guard),
        meta:   unquote(meta |> List.first)
      }
    end

    meta
    |> List.first
    |> is_list
    |> case do
      true  -> {
        meta |> List.first |> Keyword.get(:pre, opts[:pre]),
        meta |> List.first |> Keyword.get(:post, opts[:post])
      }
      false -> {opts[:pre], opts[:post]}
    end
    |> case do
      {nil, nil} ->
        quote do
          super(unquote_splicing(params))
        end
      {pre, nil} ->
        quote do
          unquote(ctx)
          unquote(pre)(ctx)
          super(unquote_splicing(params))
        end
      {nil, post} ->
        quote do
          unquote(ctx)
          try do
            super(unquote_splicing(params))
          rescue
            err -> unquote(post)(ctx, pre, err)
                   throw err
          else
            res -> unquote(post)(ctx, nil, res)
            res
          end
        end
      {pre, post} ->
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

  defp debug(env, ast) do
    ast
    |> Macro.expand(env)
    |> Macro.to_string
    ast
  end
end
