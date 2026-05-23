defmodule MotorCombate do
  @moduledoc """
  Este módulo contiene las fórmulas que seran llamadas por el Genserver de Batalla para
  visualizar los turnos, calcular los daños, visualizar los movimientos, etc.
  """

  defp visualizar_turno(turno,pokemon_activo_rival,equipo_rival,pokemon_activo_entrenador,equipo_entrenador) do

    pokemon_entrenador=Map.get(equipo_entrenador,pokemon_activo_entrenador)

    pokemon_rival=Map.get(equipo_rival,pokemon_activo_rival)

    mensaje_equipo_rival=
      Enum.map(equipo_rival, fn {pokemon,datos} ->
        cond do
          pokemon == pokemon_activo_rival ->
            "#{datos.nombre} (activo)"
          datos.salud <=0 ->
            "#{datos.nombre} (debilitado)"
          true ->
            "#{datos.nombre} (vivo)"
        end
      end)
      |>Enum.join(" | ")

    mensaje_equipo=
      Enum.map(equipo_entrenador, fn {pokemon,datos} ->
        cond do
          pokemon == pokemon_activo_entrenador ->
            "[##{pokemon}] #{datos.nombre} (activo)"
          datos.salud <=0 ->
            "[##{pokemon}] #{datos.nombre} (debilitado)"
          true ->
            "[##{pokemon}] #{datos.nombre} (vivo)"
        end
      end)
      |>Enum.join(" | ")

    movimientos=
      pokemon_entrenador.movimientos
      |> Enum.with_index(1)
      |> Enum.map(fn {movimiento, contador} ->
        "#{contador}. " <>
        "#{String.pad_trailing(movimiento.nombre, 15)} " <>
        "(#{String.pad_trailing(movimiento.elemento, 10)}) " <>
        "Poder: #{movimiento.poder}"
      end)
      |> Enum.join("\n")

    """
    ===========Turno #{turno}===========
    Rival: #{pokemon_rival.nombre} #{pokemon_rival.elemento} | Salud: #{pokemon_rival.salud}/100
    Equipo rival: #{mensaje_equipo_rival}

    Tu Pokemon: [##{pokemon_activo_entrenador}] #{pokemon_entrenador.nombre} (#{pokemon_entrenador.elemento}) | Dueño original: #{pokemon_entrenador.dueno_original} | Salud: #{pokemon_entrenador.salud}/100 | Vel: #{pokemon_entrenador.velocidad}
    Tu Equipo: #{mensaje_equipo}
    Movimientos:
    #{movimientos}

    Acciones disponibles:
    ataque <nombre_movimiento>
    cambiar <id_pokemon>
    rendirse

    Acción:
    """
  end
end
