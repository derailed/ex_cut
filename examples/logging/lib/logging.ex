defmodule EXCut.Log do
  @moduledoc """
  Cross Cutting Log concern
  """
  require Logger

  def pre(c)       , do: "> #{c.target}(#{c.args |> inspect})" |> log(c)
  def post(c, _, r), do: "< #{c.target} -> #{r}"               |> log(c)

  defp log(m, ctx) do
    ctx.meta[:level]
    |> case do
      :warn  -> m |> Logger.warn
      :debug -> m |> Logger.debug
      _      -> m |> Logger.info
    end
  end
end

defmodule Logging do
  @moduledoc """
  Demonstrates the use of annotation to inject cross-cutting logging to
  functions.
  """
  import EXCut.Log

  use ExCut, marker: :log, pre: :pre, post: :post

  require Logger

  @log level: :warn
  def elvis(a, b) when is_boolean(a), do: b

  @log level: :debug
  def elvis(a, b) when is_atom(a), do: "#{a}--#{b}"

  @log level: :info, pre: :cust_pre_log
  def elvis(a, b), do: a + b

  defp cust_pre_log(ctx) do
    msg = "[CUSTOM!] >>> Calling #{ctx.target} with args #{ctx.args |> inspect}"
    case ctx.meta[:level] do
      :info  -> Logger.info  msg
      :debug -> Logger.debug msg
    end
  end
end
