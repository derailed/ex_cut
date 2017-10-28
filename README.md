# ExCut `Cross-Cut

<div align="center" style="margin-top:10px;">
  <img src="assets/ex_cut.png"/>
</div>

[![Hex version](https://img.shields.io/hexpm/v/ex_cut.svg "Hex version")](https://hex.pm/packages/ex_ray)
[![Hex downloads](https://img.shields.io/hexpm/dt/ex_cut.svg "Hex downloads")](https://hex.pm/packages/ex_ray)
[![Build Status](https://semaphoreci.com/api/v1/projects/2873a400-892d-47db-826b-79e15a263818/1595691/shields_badge.svg)](https://semaphoreci.com/imhotep/ex_cut)


## Motivation

  ExCut defines an annotation construct that wraps a regular function and enable
  it to be decorated with a cross-cutting concern. This provide a nice mechanism
  to inject reusable behavior without cluttering your code base.

## Documentation

[ExRay](https://hexdocs.pm/ex_cut)

## Installation

  Add the following dependencies to your project (Elixir or Phoenix)

  ```elixir
  def deps do
    [
      {:ex_cut , "~> 0.1.0"}
    ]
  end
  ```

## Using

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

---
<img src="assets/imhoteplogo.png" width="32" height="auto"/> © 2017 Imhotep Software LLC.
All materials licensed under [Apache v2.0](http://www.apache.org/licenses/LICENSE-2.0)