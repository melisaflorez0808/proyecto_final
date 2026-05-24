defmodule MotorCombate do
  @moduledoc """
  Este módulo contiene las fórmulas que seran llamadas por el Genserver de Batalla para
  visualizar los turnos, calcular los daños, visualizar los movimientos, etc.
  """

  @efectividades %{
    "Acero" => %{
      "Hada" => 2.0,
      "Hielo" => 2.0,
      "Roca" => 2.0,
      "Acero" => 0.5,
      "Agua" => 0.5,
      "Electrico" => 0.5,
      "Fuego" => 0.5
    },

    "Agua" => %{
      "Fuego" => 2.0,
      "Roca" => 2.0,
      "Tierra" => 2.0,
      "Agua" => 0.5,
      "Dragon" => 0.5,
      "Planta" => 0.5
    },

    "Bicho" => %{
      "Planta" => 2.0,
      "Psiquico" => 2.0,
      "Siniestro" => 2.0,
      "Acero" => 0.5,
      "Fantasma" => 0.5,
      "Fuego" => 0.5,
      "Hada" => 0.5,
      "Lucha" => 0.5,
      "Veneno" => 0.5,
      "Volador" => 0.5
    },

    "Dragon" => %{
      "Dragon" => 2.0,
      "Acero" => 0.5,
      "Hada" => 0.0
    },

    "Electrico" => %{
      "Agua" => 2.0,
      "Volador" => 2.0,
      "Dragon" => 0.5,
      "Electrico" => 0.5,
      "Planta" => 0.5,
      "Tierra" => 0.0
    },

    "Fantasma" => %{
      "Fantasma" => 2.0,
      "Psiquico" => 2.0,
      "Siniestro" => 0.5,
      "Normal" => 0.0
    },

    "Fuego" => %{
      "Acero" => 2.0,
      "Bicho" => 2.0,
      "Hielo" => 2.0,
      "Planta" => 2.0,
      "Agua" => 0.5,
      "Dragon" => 0.5,
      "Fuego" => 0.5,
      "Roca" => 0.5
    },

    "Hada" => %{
      "Dragon" => 2.0,
      "Lucha" => 2.0,
      "Siniestro" => 2.0,
      "Acero" => 0.5,
      "Fuego" => 0.5,
      "Veneno" => 0.5
    },

    "Hielo" => %{
      "Dragon" => 2.0,
      "Planta" => 2.0,
      "Tierra" => 2.0,
      "Volador" => 2.0,
      "Acero" => 0.5,
      "Agua" => 0.5,
      "Fuego" => 0.5,
      "Hielo" => 0.5
    },

    "Lucha" => %{
      "Acero" => 2.0,
      "Hielo" => 2.0,
      "Normal" => 2.0,
      "Roca" => 2.0,
      "Siniestro" => 2.0,
      "Bicho" => 0.5,
      "Hada" => 0.5,
      "Psiquico" => 0.5,
      "Veneno" => 0.5,
      "Volador" => 0.5,
      "Fantasma" => 0.0
    },

    "Normal" => %{
      "Roca" => 0.5,
      "Acero" => 0.5,
      "Fantasma" => 0.0
    },

    "Planta" => %{
      "Agua" => 2.0,
      "Roca" => 2.0,
      "Tierra" => 2.0,
      "Acero" => 0.5,
      "Bicho" => 0.5,
      "Dragon" => 0.5,
      "Fuego" => 0.5,
      "Planta" => 0.5,
      "Veneno" => 0.5,
      "Volador" => 0.5
    },

    "Psiquico" => %{
      "Lucha" => 2.0,
      "Veneno" => 2.0,
      "Acero" => 0.5,
      "Psiquico" => 0.5,
      "Siniestro" => 0.0
    },

    "Roca" => %{
      "Bicho" => 2.0,
      "Fuego" => 2.0,
      "Hielo" => 2.0,
      "Volador" => 2.0,
      "Acero" => 0.5,
      "Lucha" => 0.5,
      "Tierra" => 0.5
    },

    "Siniestro" => %{
      "Fantasma" => 2.0,
      "Psiquico" => 2.0,
      "Hada" => 0.5,
      "Lucha" => 0.5,
      "Siniestro" => 0.5
    },

    "Tierra" => %{
      "Acero" => 2.0,
      "Electrico" => 2.0,
      "Fuego" => 2.0,
      "Roca" => 2.0,
      "Veneno" => 2.0,
      "Bicho" => 0.5,
      "Planta" => 0.5,
      "Volador" => 0.0
    },

    "Veneno" => %{
      "Hada" => 2.0,
      "Planta" => 2.0,
      "Fantasma" => 0.5,
      "Roca" => 0.5,
      "Tierra" => 0.5,
      "Veneno" => 0.5,
      "Acero" => 0.0
    },

    "Volador" => %{
      "Bicho" => 2.0,
      "Lucha" => 2.0,
      "Planta" => 2.0,
      "Acero" => 0.5,
      "Electrico" => 0.5,
      "Roca" => 0.5
    }
  }

  @doc """
  Función para visualizar turnos por consola, recibe como parámetros:
   - Turno en el que van actualmente
   - El id del pokemon activo del rival
   - Un mapa del equipo rival en la que las claves son los id de los pokemones y guardan todas sus estadisticas
   - El id del pokemon activo del entrenador
   - Un mapa del equipo del entrenador en la que las claves son los id de los pokemones y guardan todas sus estadisticas
  """

  def visualizar_turno(turno,pokemon_activo_rival,equipo_rival,pokemon_activo_entrenador,equipo_entrenador) do

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
            "[#{pokemon}] #{datos.nombre} (activo)"
          datos.salud <=0 ->
            "[#{pokemon}] #{datos.nombre} (debilitado)"
          true ->
            "[#{pokemon}] #{datos.nombre} (vivo)"
        end
      end)
      |>Enum.join(" | ")

    movimientos=
      pokemon_entrenador.movimientos
      |> Enum.with_index(1)
      |> Enum.map(fn {movimiento, contador} ->
        "#{contador}. " <>
        "#{String.pad_trailing(movimiento.nombre, 15)} " <>
        "(#{String.pad_trailing(movimiento.elemento <> ",", 11)} " <>
        "Poder: #{movimiento.poder})"
      end)
      |> Enum.join("\n")

    """
    ===========Turno #{turno}===========
    Rival: #{pokemon_rival.nombre} #{pokemon_rival.elemento} | Salud: #{pokemon_rival.salud}/100
    Equipo rival: #{mensaje_equipo_rival}

    Tu Pokemon: [#{pokemon_activo_entrenador}] #{pokemon_entrenador.nombre} (#{pokemon_entrenador.elemento}) | Dueño original: #{pokemon_entrenador.dueno_original} | Salud: #{pokemon_entrenador.salud}/100 | Vel: #{pokemon_entrenador.velocidad}
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

  @doc """
  La función de obtener efectividad recibe el tipo de ataque y los tipos defensor que pueden ser por ejemplo =>
   tipo_ataque = "Electrico"
   tipos_defensor = ["Agua", "Volador"]
  La función recorre la lista de tipos defensor y utiliza la constante definida de efectividades para conseguir el valor de la efectividad
  o en su defecto 1. Se debe tener en cuenta que hay ataques que la efectividad es 0, lo que anularía el daño, por ejemplo un ataque de lucha
  contra
  """

  def obtener_efectividad(tipo_ataque, tipos_defensor) do
    Enum.reduce(tipos_defensor, 1.0, fn tipo_defensor, acumulado ->
      multiplicador =
        @efectividades
        |> Map.get(tipo_ataque)
        |> Map.get(tipo_defensor, 1.0)

        acumulado * multiplicador
    end)
  end

  def calcular_dano(poder_movimiento,ataque_atacante,defensa_defensor,tipos_atacante,tipo_ataque,tipos_defensor) do
    stab =
      if tipo_ataque in tipos_atacante, do: 1.5, else: 1.0
    factor_aleatorio= :rand.uniform() * 0.15 + 0.85

    dano_base=trunc((poder_movimiento*(ataque_atacante/defensa_defensor))/5+2)
    dano_final=trunc(dano_base*obtener_efectividad(tipo_ataque,tipos_defensor)*stab*factor_aleatorio)

    max(1,dano_final)

  end

end
