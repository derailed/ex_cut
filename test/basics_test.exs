defmodule ExCut.BasicsTest do
  use ExUnit.Case
  doctest ExCut

  use ExCut, marker: :test, pre: :f1, post: :f2

  @test kind: :plain
  def test1(a, b), do: a + b

  test "plain" do
    assert test1(1, 2) == 3
    assert_received :f1
    assert_received :f2
  end

  @test kind: :default_arg
  def test2(a, b \\ 2), do: a + b

  test "default argument" do
    assert test2(1, 2) == 3
    assert_received :f1
    assert_received :f2

    assert test2(1) == 3
    assert_received :f1
    assert_received :f2
  end

  @test pre: :f1_1, post: :f2_1
  def test3(a), do: a
  @test pre: :f1_1, post: :f2_1
  def test3(a, b), do: a + b
  @test pre: :f1_1, post: :f2_1
  def test3(a, b, c), do: a + b + c

  test "overload" do
    assert test3(1)  == 1
    assert_received :f1_1
    assert_received :f2_1

    assert test3(1, 2) == 3
    assert_received :f1_1
    assert_received :f2_1

    assert test3(1, 2, 3) == 6
    assert_received :f1_1
    assert_received :f2_1
  end

  @test kind: :guard
  def test4(a) when is_binary(a), do: "test " <> a
  @test kind: :guard
  def test4(a) when is_number(a), do: a
  @test kind: :guard
  def test4(a), do: a

  test "guard" do
    assert test4("yo!") == "test yo!"
    assert_received :f1
    assert_received :f2

    assert test4(10)    == 10
    assert_received :f1
    assert_received :f2

    assert test4(true) == true
    assert_received :f1
    assert_received :f2
  end

  @test kind: :ignored
  def test6(a, _b), do: "test #{a}"

  test "ignored" do
    assert test6(10, 20) == "test 10"
    assert_received :f1
    assert_received :f2
  end

  @test kind: :map
  def test7(%{a: a, b: _b}), do: a

  test "map" do
    assert test7(%{a: 1, b: 2}) == 1
    assert_received :f1
    assert_received :f2
  end

  defmodule Rec do
    defstruct [:blee, :fred]
  end

  @test kind: :rec
  def test7(%Rec{blee: b, fred: f}), do: "test #{b} -- #{f}"

  test "rec" do
    assert test7(%Rec{blee: 1, fred: 2}) == "test 1 -- 2"
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

  def f1_1(_ctx) do
    self() |> send(:f1_1)
    1
  end
  def f2_1(ctx, pre, res) do
    self() |> send(:f2_1)

    assert pre == 1
    case length(ctx.args) do
      1 -> assert(res) == 1
      2 -> assert(res) == 3
      3 -> assert(res) == 6
    end
  end
end
