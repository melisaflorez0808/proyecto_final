defmodule BatallasPokemonTest do
  use ExUnit.Case
  doctest BatallasPokemon

  test "greets the world" do
    assert BatallasPokemon.hello() == :world
  end
end
