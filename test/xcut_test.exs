defmodule XCutTest do
  use ExUnit.Case
  doctest XCut

  use XCut, marker: :test, pre: :f1, post: :f2

  def f1(fun: _f, meta: _m) do
    1
  end
  def f2(_ctx, pre) do
    assert pre == 1
  end

  def f1_1(_ctx) do
    2
  end
  def f1_2(_ctx, pre) do
    assert pre == 2
  end

  @test :plain
  def test1(a, b), do: a + b

  @test [pre: :f1_1, post: :f1_2]
  def test1(a), do: a

  test "plain" do
    assert test1(1,2) == 3
    assert test1(1) == 1
  end

  @test :default
  def test2(a, b \\ 1), do: a+b

  test "defaults" do
    assert test2(1,2) == 3
    assert test2(1) == 2
  end

  @test :multi
  def test3(a), do: a
  @test :multi
  def test3(a,b), do: a+b
  @test :multi
  def test3(a,b,c), do: a+b+c

  test "mutli" do
    assert test3(1,2) == 3
    assert test3(1) == 1
    assert test3(1,2,3) == 6
  end

  @test :guard
  def test4(a) when is_binary(a), do: "test " <> a
  @test :guard
  def test4(a) when is_number(a), do: a

  test "guard" do
    assert test4("yo!") == "test yo!"
    assert test4(10) == 10
  end

  @test :patterns
  def test5(fred: f, blee: b), do: "test #{f}/#{b}"
  @test :patterns
  def test5(blee: b), do: "test #{b}"
  @test :patterns
  def test5(fred: f), do: "test #{f}"

  test "patterns" do
    assert test5(fred: 10, blee: "yo") == "test 10/yo"
    assert test5(blee: 10) == "test 10"
    assert test5(fred: 20) == "test 20"
  end
end
