defmodule BatallasPokemonTest do
  use ExUnit.Case

  test "el daño siempre es mayor que 0" do
    dano =
      MotorCombate.calcular_dano(
        50,
        100,
        50,
        ["Fuego"],
        "Fuego",
        ["Planta"]
      )

    assert dano > 0
  end

  test "un ataque super efectivo hace más daño que uno normal" do
    dano_super =
      MotorCombate.calcular_dano(
        50,
        100,
        50,
        ["Fuego"],
        "Fuego",
        ["Planta"]
      )

    dano_normal =
      MotorCombate.calcular_dano(
        50,
        100,
        50,
        ["Normal"],
        "Normal",
        ["Agua"]
      )

    assert dano_super > dano_normal
  end

  test "pokemon mas rapido ataca primero" do

    [primero,segundo]=MotorCombate.orden_por_velocidad({:creador, 30}, {:contrincante, 50})


    assert primero == :contrincante
    assert segundo == :creador
  end

  


end
