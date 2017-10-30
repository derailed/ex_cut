defmodule LoggingTest do
  use ExUnit.Case
  doctest Logging

  test "greets the world" do
    assert Logging.hello() == :world
  end
end
