defmodule AmqpToHttpTest do
  use ExUnit.Case
  doctest AmqpToHttp

  test "greets the world" do
    assert AmqpToHttp.hello() == :world
  end
end
