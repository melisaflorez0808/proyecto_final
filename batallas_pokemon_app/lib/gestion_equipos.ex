defmodule GestionEquipos do
  @moduledoc """
  Este módulo contiene los métodos para gestionar los equipos pokemon
  """

  @doc """
  El metodo crear equipo recibe los parámetros desde el servidor:
  - nombre del equipo
  - ids de los pokemones a ingresar al equipo
  - entrenador completo con todos los campos
  La función retorna el entrenador actualizado con el nuevo equipo
  """

  def crear_equipo(nombre_equipo, ids, entrenador) do
    pokemones =
      String.split(ids, " ")
      |> Enum.map(fn id ->
        buscar_pokemon(entrenador.inventario, id)
      end)
      |> Enum.filter(fn id_pokemon ->
        id_pokemon != nil
      end)

    case Equipo.nuevo(pokemones) do
      {:ok, nuevo_equipo} ->
        if Map.has_key?(entrenador.equipos, nombre_equipo) do
          {:error, :nombre_equipo_duplicado}
        else
          equipos_actualizado = Map.put(entrenador.equipos, nombre_equipo, nuevo_equipo)
          entrenador_actualizado = %{entrenador | equipos: equipos_actualizado}
          {:equipo_creado, entrenador_actualizado}
        end

      {:error, razon} ->
        {:error, razon}
    end
  end

  @doc """
  Función para buscar pokemones en el inventario del entrenador y en caso de encontrarlo
  retorna id para ser incluido en equipo. Recibe por parámetro:
  - inventario del entrenador
  - id del pokemon a buscar
  """

  def buscar_pokemon(inventario, id) do
    case Map.get(inventario, id) do
      nil ->
        nil

      _pokemon ->
        id
    end
  end

  @doc """
  Las funciones de listar_equipos reciben un entrenador y retornan el mensaje con los
  equipos guardados por entrenador
  """

  def listar_equipos(entrenador) when map_size(entrenador.equipos) == 0,
    do: {:ok, "No tiene equipos guardados a la fecha"}

  def listar_equipos(entrenador) do
    equipos =
      Enum.map(entrenador.equipos, fn {nombre, equipo} ->
        lista_pokemones =
          Enum.map(equipo.pokemones, fn id_pokemon ->
            case Map.get(entrenador.inventario, id_pokemon) do
              nil ->
                "[#{id_pokemon}] sin pokemon en inventario"

              pokemon ->
                "[#{id_pokemon}] #{pokemon.especie}"
            end
          end)
          |> Enum.join(", ")

        "#{String.pad_trailing(nombre, 10)} [#{length(equipo.pokemones)}/3]: #{lista_pokemones}"
      end)
      |> Enum.join("\n")

    equipo_activo =
      if entrenador.equipo_activo == nil do
        "No tiene un equipo activo"
      else
        entrenador.equipo_activo
      end

    mensaje =
      """
      Equipos guardados:
      #{equipos}

      Equipo activo actualmente: #{equipo_activo}
      """

    {:ok, mensaje}
  end

  @doc """
  Las funcion quitar_pokemon_equipo recibe por parámetro:
  - nombre del equipo al que desea retirar un pokemon
  - id del pokemon que desea retirar
  - entrenador completo con todos los campos
  La función retorna el entrenador actualizado con el pokemon eliminado del equipo
  """

  def quitar_pokemon_equipo(nombre_equipo, id_pokemon, entrenador) do
    case Map.get(entrenador.equipos, nombre_equipo) do
      nil ->
        {:error, :no_existe_nombre_equipo}

      equipo ->
        cond do
          nombre_equipo == entrenador.equipo_activo ->
            {:error, :equipo_activo_para_batalla}

          length(equipo.pokemones) == 1 ->
            {:error, :equipo_necesita_al_menos_un_pokemon}

          true ->
            case Equipo.quitar_pokemon(equipo, id_pokemon) do
              {:error, razon} ->
                {:error, razon}

              {:ok, equipo_nuevo} ->
                equipos_actualizado = Map.put(entrenador.equipos, nombre_equipo, equipo_nuevo)
                entrenador_actualizado = %{entrenador | equipos: equipos_actualizado}
                {:pokemon_eliminado, entrenador_actualizado}
            end
        end
    end
  end

  @doc """
  Las funcion agregar_pokemon_equipo recibe por parámetro:
  - nombre del equipo al que desea agregar un pokemon
  - id del pokemon que desea agregar
  - entrenador completo con todos los campos
  La función retorna el entrenador actualizado con el pokemon agregado al equipo
  """

  def agregar_pokemon_equipo(nombre_equipo, id_pokemon, entrenador) do
    case Map.get(entrenador.equipos, nombre_equipo) do
      nil ->
        {:error, :no_existe_nombre_equipo}

      equipo ->
        cond do
          length(equipo.pokemones) >= 3 ->
            {:error, :equipo_con_cupo_maximo}

          Map.has_key?(entrenador.inventario, id_pokemon) ->
            case Equipo.agregar_pokemon(equipo, id_pokemon) do
              {:error, razon} ->
                {:error, razon}

              {:ok, equipo_nuevo} ->
                equipos_actualizado = Map.put(entrenador.equipos, nombre_equipo, equipo_nuevo)
                entrenador_actualizado = %{entrenador | equipos: equipos_actualizado}
                {:pokemon_agregado, entrenador_actualizado}
            end

          true ->
            {:error, :no_tiene_pokemon_inventario}
        end
    end
  end

  @doc """
  Las funcion usar_equipo recibe por parámetro:
  - Nombre del equipo a usar
  - entrenador completo con todos los campos
  La función retorna el entrenador actualizado con el equipo a usar activo
  """

  def usar_equipo(nombre_equipo, entrenador) do
    case Map.get(entrenador.equipos, nombre_equipo) do
      nil ->
        {:error, :no_existe_nombre_equipo}

      equipo ->
        validar =
          Enum.filter(equipo.pokemones, fn id_pokemon ->
            not Map.has_key?(entrenador.inventario, id_pokemon)
          end)

        cond do
          validar != [] ->
            {:error, :equipo_pokemones_faltantes, validar}

          nombre_equipo == entrenador.equipo_activo ->
            {:error, :equipo_activo_batalla}

          true ->
            entrenador_actualizado = %{entrenador | equipo_activo: nombre_equipo}

            {:equipo_activo, entrenador_actualizado}
        end
    end
  end

  @doc """
  Las funcion armar_equipo_batalla recibe por parámetro:
  - Pokemones Base del Programa
  - Entrenador completo con todos los campos
  - Id del Pokemon Inicial
  La función retorna el equipo armado en forma de mapa para usar en batalla
  """


  def armar_equipo_batalla(pokemones_base, entrenador, pokemon_inicial) do

    nombre_equipo = entrenador.equipo_activo
    #Obtengo los ids de los pokemones del equipo activo
    equipo = Map.get(entrenador.equipos, nombre_equipo)

    if equipo == nil do
      {:error, "Equipo no encontrado"}
    else
      equipo_batalla =
        Enum.reduce(equipo.pokemones, %{}, fn id_pokemon, acc ->

            pokemon_inventario = Map.get(entrenador.inventario, id_pokemon)

            if pokemon_inventario == nil do
              acc
            else
              pokemon_base = Map.get(pokemones_base, pokemon_inventario.especie)

              pokemon_batalla = %{
                id: id_pokemon,
                especie: pokemon_inventario.especie,
                elemento: pokemon_base.tipos,
                dueno_original: pokemon_inventario.dueno_original,
                salud: 100,
                ataque: pokemon_inventario.ataque,
                defensa: pokemon_inventario.defensa,
                velocidad: pokemon_inventario.velocidad,
                movimientos: pokemon_inventario.movimientos
              }
              Map.put(acc, id_pokemon, pokemon_batalla)
            end
        end)

      # VALIDAR POKEMON INICIAL
      if Map.has_key?(equipo_batalla, pokemon_inicial) do
        {:ok, equipo_batalla, pokemon_inicial}
      else
        {:error, "El pokemon inicial no pertenece al equipo"}
      end
    end
  end
end
