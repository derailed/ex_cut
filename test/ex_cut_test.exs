defmodule EXCutTest do
  use ExUnit.Case
  doctest ExCut

  use ExCut, marker: :test, pre: :f1, post: :f2

  @test :plain
  def test1(a, b), do: a + b

  @test [pre: :f1_1, post: :f1_2]
  def test1(a), do: a

  test "plain" do
    assert test1(1, 2) == 3
    assert test1(1)    == 1
  end

  @test :default
  def test2(a, b \\ 1), do: a + b

  test "defaults" do
    assert test2(1, 2) == 3
    assert test2(1)    == 2
  end

  @test :multi
  def test3(a), do: a
  @test :multi
  def test3(a, b), do: a + b
  @test :multi
  def test3(a, b, c), do: a + b + c

  test "mutli" do
    assert test3(1, 2)    == 3
    assert test3(1)       == 1
    assert test3(1, 2, 3) == 6
  end

  @test :guard
  def test4(a) when is_binary(a), do: "test " <> a
  @test :guard
  def test4(a) when is_number(a), do: a

  test "guard" do
    assert test4("yo!") == "test yo!"
    assert test4(10)    == 10
  end

  @test :patterns
  def test5(fred: f, blee: b), do: "test #{f}/#{b}"
  @test :patterns
  def test5(blee: b), do: "test #{b}"
  @test :patterns
  def test5(fred: f), do: "test #{f}"
  @test :patterns
  def test5(%{fred: _f, blee: _b}), do: "test"

  test "patterns" do
    assert test5(fred: 10, blee: "yo")  == "test 10/yo"
    assert test5(blee: 10)              == "test 10"
    assert test5(fred: 20)              == "test 20"
    assert test5(%{fred: 10, blee: 20}) == "test"
  end

  @test :dontcare
  def test6(a, b), do: test_6_1(a, b)
  @test :dontcare
  def test_6_1(a, _b), do: "test #{a}"

  test "dontcare" do
    assert test6(10, 20) == "test 10"
  end

  defmodule Rec do
    defstruct [:blee, :fred]
  end

  @test :rec
  def test7(%Rec{blee: b, fred: f}), do: "test #{b} -- #{f}"

  test "rec" do
    assert test7(%Rec{blee: 1, fred: 2}) == "test 1 -- 2"
  end

  def f1(_ctx) do
    1
  end
  def f2(_ctx, pre, _res) do
    assert pre == 1
  end

  def f1_1(_ctx) do
    2
  end
  def f1_2(_ctx, pre, _res) do
    assert pre == 2
  end
end
