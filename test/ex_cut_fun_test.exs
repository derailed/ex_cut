defmodule AspexFunTest do
  use ExUnit.Case
  use ExCut, marker: :test, pre: :f1, post: :f2

  @test :defaults
  def test1(a, b), do: a + b

  test "plain" do
    assert test1(1, 2) == 3
  end

  def f1(_ctx) do
    IO.puts "Called f1"
    1
  end
  def f2(_ctx, pre, _res) do
    IO.puts "Called f2"
    assert pre == 1
  end
end
