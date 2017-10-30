defmodule ExCut.DisabledTest do
  use ExUnit.Case

  use ExCut, marker: :test, pre: :f1, post: :f2, enabled: false

  @test kind: :override
  def test1(a, b) when is_boolean(a), do: b

  def test1(a, b), do: a + b

  test "no annotation" do
    assert test1(3, 1) == 4

    refute_receive :f1
    refute_receive :f2
  end

  test "called with bool" do
    assert test1(true, 4)  == 4
    refute_receive :f1
    refute_receive :f2
  end

  def f1(_ctx) do
    IO.puts "F1"
    send self(), :f1
    1
  end

  def f2(_ctx, pre, res) do
    IO.puts "F2"

    assert pre == 1
    assert res == 4
    send self(), :f2
  end
end
