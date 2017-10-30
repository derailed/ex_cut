defmodule ExCut.TagFunTest do
  use ExUnit.Case

  use ExCut, marker: :test, pre: :f1, post: :f2

  @test pre: :f1_1, post: :f2_1
  def test1(a, b), do: a + b

  test "plain" do
    assert test1(1, 2) == 3

    assert_received :f1_1
    assert_received :f2_1
    refute_received :f1
    refute_received :f2
  end

  def f1(_ctx) do
    self() |> send(:f1)
    1
  end
  def f2(_ctx, pre, _res) do
    self() |> send(:f2)
    assert pre == 1
  end

  def f1_1(_ctx) do
    self() |> send(:f1_1)
    1
  end
  def f2_1(_ctx, pre, res) do
    assert res == 3
    assert pre == 1

    self() |> send(:f2_1)
  end
end
