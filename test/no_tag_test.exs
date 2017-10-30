defmodule ExCut.NoTagTest do
  use ExUnit.Case
  doctest ExCut

  use ExCut, marker: :test, pre: :f1, post: :f2

  @test kind: :meta
  def test1(a)   , do: a
  def test1(a, b), do: a + b

  test "no meta" do
    assert test1(1, 2) == 3

    refute_received :f1
    refute_received :f2
  end

  test "meta" do
    assert test1(1) == 1

    assert_received :f1
    assert_received :f2
  end

  def f1(_ctx) do
    self() |> send(:f1)
    1
  end
  def f2(_ctx, pre, _res) do
    self() |> send(:f2)
    assert pre == 1
  end
end
