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

  def crear_equipo(nombre_equipo,ids,entrenador) do
    pokemones=
      String.split(ids," ")
      |>Enum.map(fn id ->
        buscar_pokemon(entrenador.inventario,id)
      end)
      |>Enum.filter(fn id_pokemon ->
        id_pokemon != nil
      end)

      case Equipo.nuevo(pokemones) do
      {:ok,nuevo_equipo} ->
        if Map.has_key?(entrenador.equipos,nombre_equipo) do
          {:error, :nombre_equipo_duplicado}
        else
          equipos_actualizado= Map.put(entrenador.equipos,nombre_equipo,nuevo_equipo)
          entrenador_actualizado= %{entrenador | equipos: equipos_actualizado}
          {:equipo_creado,entrenador_actualizado}
        end
      {:error,razon} ->
        {:error,razon}
      end
    end

  @doc """
  Función para buscar pokemones en el inventario del entrenador y en caso de encontrarlo
  retorna id para ser incluido en equipo. Recibe por parámetro:
  - inventario del entrenador
  - id del pokemon a buscar
  """

  def buscar_pokemon(inventario,id) do
    case Map.get(inventario, id) do
      nil -> IO.puts("Pokemon con id #{id} no esta en su inventario")
        nil
      _pokemon -> IO.puts("Pokemon con id #{id} agregado")
        id
    end
  end

  @doc """
  Las funciones de listar_equipos reciben un entrenador y retornan el mensaje con los
  equipos guardados por entrenador
  """

  def listar_equipos(entrenador) when map_size(entrenador.equipos)==0, do: {:ok, "No tiene equipos guardados a la fecha"}

  def listar_equipos(entrenador) do
    equipos=
      Enum.map(entrenador.equipos, fn {nombre,equipo} ->
        lista_pokemones=
          Enum.map(equipo.pokemones, fn id_pokemon ->
            pokemon=
              Map.get(entrenador.inventario,id_pokemon)
            "[#{id_pokemon}] #{pokemon.especie}"
          end)
          |>Enum.join(", ")
        "#{String.pad_trailing(nombre,10)} [#{length(equipo.pokemones)}/3]: #{lista_pokemones}"
      end)
      |>Enum.join("\n")

    mensaje=
      "Equipos guardados:\n" <> equipos

    {:ok,mensaje}
    end

    @doc """
    Las funcion quitar_pokemon_equipo recibe por parámetro:
    - nombre del equipo al que desea retirar un pokemon
    - id del pokemon que desea retirar
    - entrenador completo con todos los campos
    La función retorna el entrenador actualizado con el pokemon eliminado del equipo
    """

    def quitar_pokemon_equipo(nombre_equipo,id_pokemon,entrenador) do

      case Map.get(entrenador.equipos,nombre_equipo) do
        nil ->
          {:error, :no_existe_nombre_equipo}

        equipo ->
          cond do
            Enum.member?(entrenador.equipos[nombre_equipo].pokemones, id_pokemon) and nombre_equipo==entrenador.equipo_activo ->
              {:error, :pokemon_pertenece_a_equipo_activo}

            length(equipo.pokemones) ==1 ->
              {:error, :equipo_necesita_al_menos_un_pokemon}

            true ->
              case Equipo.quitar_pokemon(equipo,id_pokemon) do
              {:error,razon} ->
                {:error,razon}
              {:ok,equipo_nuevo} ->
                equipos_actualizado= Map.put(entrenador.equipos,nombre_equipo,equipo_nuevo)
                entrenador_actualizado= %{entrenador | equipos: equipos_actualizado}
                {:pokemon_eliminado,entrenador_actualizado}
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

      def agregar_pokemon_equipo(nombre_equipo,id_pokemon,entrenador) do

        case Map.get(entrenador.equipos,nombre_equipo) do
          nil ->
            {:error, :no_existe_nombre_equipo}

          equipo ->
          cond do
            length(equipo.pokemones) >=3 ->
              {:error, :equipo_con_cupo_maximo}
            Map.has_key?(entrenador.inventario,id_pokemon) ->
              case Equipo.agregar_pokemon(equipo,id_pokemon) do
                {:error,razon} ->
                  {:error,razon}
                {:ok,equipo_nuevo} ->
                  equipos_actualizado= Map.put(entrenador.equipos,nombre_equipo,equipo_nuevo)
                  entrenador_actualizado= %{entrenador | equipos: equipos_actualizado}
                  {:pokemon_agregado,entrenador_actualizado}
              end
            true ->
              {:error, :no_tiene_pokemon_inventario}
            end
          end
        end

  end
