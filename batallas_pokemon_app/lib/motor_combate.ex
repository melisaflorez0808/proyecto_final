defmodule MotorCombate do

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

  def calcular_dano(poder, ataque, defensa, tipos_atacante, tipo_mov, tipos_defensor) do

    #Bonificación Por Ataque del Mismo Tipo
    stab = if tipo_mov in tipos_atacante, do: 1.5, else: 1.0

    tipo_mov = String.capitalize(tipo_mov)

    tipos_defensor =
      Enum.map(tipos_defensor, &String.capitalize/1)

    tipos_atacante =
      Enum.map(tipos_atacante, &String.capitalize/1)

    efectividad = obtener_efectividad(tipo_mov, tipos_defensor)

    factor = :rand.uniform() * 0.15 + 0.85

    dano_base = trunc((poder*(ataque/defensa))/5+2)
    dano_final = trunc(dano_base * efectividad * stab * factor)
    max(1,dano_final)
  end

  def obtener_efectividad(tipo_ataque, tipos_defensor) do
    Enum.reduce(tipos_defensor, 1.0, fn tipo_defensor, acumulado ->

      tabla_tipo = Map.get(@efectividades, tipo_ataque, %{})

      multiplicador =
        Map.get(tabla_tipo, tipo_defensor, 1.0)

      acumulado * multiplicador
    end)
  end

  #==================== Orden Por Velocidad ====================
  def orden_por_velocidad({:creador, velocidad_creador}, {:contrincante, velocidad_contrincante}) do
    cond do
      velocidad_creador > velocidad_contrincante -> [:creador, :contrincante]
      velocidad_contrincante > velocidad_creador -> [:contrincante, :creador]
      true -> Enum.shuffle([:creador, :contrincante])
    end
  end

  def visualizar_turno(turno, pokemon_activo_rival, equipo_rival, pokemon_activo_entrenador, equipo_entrenador) do

    pokemon_entrenador = Map.get(equipo_entrenador, pokemon_activo_entrenador)

    pokemon_rival = Map.get(equipo_rival, pokemon_activo_rival)

    mensaje_equipo_rival=
      Enum.map(equipo_rival, fn {pokemon, datos} ->
        cond do
          pokemon == pokemon_activo_rival ->
            "#{datos.especie} (activo)"
          datos.salud <=0 ->
            "#{datos.especie} (debilitado)"
          true ->
            "#{datos.especie} (vivo)"
        end
      end)
      |> Enum.join(" | ")

    mensaje_equipo=
      Enum.map(equipo_entrenador, fn {pokemon, datos} ->
        cond do
          pokemon == pokemon_activo_entrenador ->
            "[#{pokemon}] #{datos.especie} (activo)"
          datos.salud <=0 ->
            "[#{pokemon}] #{datos.especie} (debilitado)"
          true ->
            "[#{pokemon}] #{datos.especie} (vivo)"
        end
      end)
      |> Enum.join(" | ")

    movimientos =
      pokemon_entrenador.movimientos
      |> Enum.with_index(1)
      |> Enum.map(fn {movimiento, contador} ->
        "#{contador}. " <>
        "#{String.pad_trailing(movimiento.nombre, 15)} " <>
        "(#{String.pad_trailing(movimiento.tipo <> ",", 11)} " <>
        "Poder: #{movimiento.poder_base})"
      end)
      |> Enum.join("\n")

    """

    ================================= Turno #{turno} =================================
    Rival: #{pokemon_rival.especie} (#{Enum.join(pokemon_rival.elemento, "/")}) | Salud: #{pokemon_rival.salud}/100
    Equipo rival: #{mensaje_equipo_rival}

    Tu Pokemon: [#{pokemon_activo_entrenador}] #{pokemon_entrenador.especie} (#{pokemon_entrenador.elemento}) | Dueño original: #{pokemon_entrenador.dueno_original} | Salud: #{pokemon_entrenador.salud}/100 | Vel: #{pokemon_entrenador.velocidad}
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
