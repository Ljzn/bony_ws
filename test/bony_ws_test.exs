defmodule BonyWsTest do
  use ExUnit.Case
  doctest BonyWs

  test "greets the world" do
    assert BonyWs.hello() == :world
  end
end
