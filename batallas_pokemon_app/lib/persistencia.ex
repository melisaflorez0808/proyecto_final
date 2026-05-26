defmodule Persistencia do

  @moduledoc """
  Modulo para la lectura y escritura de archivos
  """

  def leer_movimientos() do
    case File.read("data/moves.json") do
      {:ok, contenido} ->
        Jason.decode!(contenido)
        |> Enum.map(fn {clase, lista_movimientos} ->
          movimientos=
            Enum.map(lista_movimientos, fn movimiento ->
              %Movimiento{
                nombre: movimiento["nombre"],
                tipo: movimiento["tipo"],
                poder_base: movimiento["poder_base"]
              }
            end)
            {clase,movimientos}
          end)
          |> Map.new()

      {:error, _} ->
        %{}
    end
  end

  def leer_pokemones() do
    case File.read("data/pokemon.json") do
      {:ok, contenido} ->
        Jason.decode!(contenido)
        |> Enum.map(fn {especie, datos} ->
          {
            especie,
            %EspeciePokemon{
              tipos: datos["tipos"],
              ataque_base: datos["ataque_base"],
              defensa_base: datos["defensa_base"],
              velocidad_base: datos["velocidad_base"]
            }
          }
        end)
        |> Map.new()

      {:error, _} ->
        %{}
    end
  end

  def leer_tienda() do
    case File.read("data/tienda.json") do
      {:ok, contenido} ->
        Jason.decode!(contenido)
        |> Enum.map(fn {sobre, datos_sobre} ->
          {
            sobre,
            %Sobre{
              precio: datos_sobre["precio"],
              probabilidades: datos_sobre["probabilidades"]
            }
          }
        end)
        |> Map.new()

      {:error, _} ->
        %{}
    end
  end

  def leer_entrenadores() do
    case File.read("data/trainers.json") do
      {:ok, contenido} ->
        Jason.decode!(contenido)
        |> Enum.map(fn {usuario, datos} ->
          {
            usuario,
            %Entrenador{
              nombre: datos["nombre"],
              clave: datos["clave"],
              victorias: datos["victorias"],
              monedas_actuales: datos["monedas_actuales"],
              monedas_acumuladas: datos["monedas_acumuladas"],
              equipo_activo: datos["equipo_activo"],
              inventario: leer_pokemones_instanciados(datos["inventario"] || %{}),
              sobres_pendientes: leer_sobres_pendientes(datos["sobres_pendientes"] || %{}),
              equipos: leer_equipos(datos["equipos"] || %{})
            }
          }
        end)
        |> Map.new()

      {:error, _} ->
        %{}
    end
  end

  def leer_pokemones_instanciados(contenido) do
    Enum.map(contenido, fn {id, pokemon} ->
      movimientos =
        Enum.map(pokemon["movimientos"], fn mov ->
          %Movimiento{
            nombre: mov["nombre"],
            tipo: mov["tipo"],
            poder_base: mov["poder_base"]
          }
        end)

      {
        id,
        %PokemonInstancia{
          id: pokemon["id"],
          especie: pokemon["especie"],
          dueno_original: pokemon["dueno_original"],
          rareza: pokemon["rareza"],
          ataque: pokemon["ataque"],
          defensa: pokemon["defensa"],
          velocidad: pokemon["velocidad"],
          movimientos: movimientos
        }
      }
    end)
    |> Map.new()
  end

  def leer_sobres_pendientes(contenido) do
    Enum.map(contenido, fn {id, sobre} ->
      {
        id,
        %SobrePendiente{
          tipo: sobre["tipo"]
        }
      }
    end)
    |> Map.new()
  end

  def leer_equipos(contenido) do
    Enum.map(contenido, fn {nombre, equipo} ->
      {
        nombre,
        %Equipo{
          pokemones: equipo["pokemones"]
        }
      }
    end)
    |> Map.new()
  end

  def escribir_entrenador(mapa) do
    json=Enum.map(mapa,fn {usuario, datos} ->
        {
          usuario,
          %{
            nombre: datos.nombre,
            clave: datos.clave,
            victorias: datos.victorias,
            monedas_actuales: datos.monedas_actuales,
            monedas_acumuladas: datos.monedas_acumuladas,
            equipo_activo: datos.equipo_activo,
            inventario:
              Enum.map(datos.inventario, fn {id,pokemon} ->
                {
                  id,
                  %{
                    id: pokemon.id,
                    especie: pokemon.especie,
                    dueno_original: pokemon.dueno_original,
                    rareza: pokemon.rareza,
                    ataque: pokemon.ataque,
                    defensa: pokemon.defensa,
                    velocidad: pokemon.velocidad,
                    movimientos:
                      Enum.map(pokemon.movimientos, fn mov ->
                        %{
                          nombre: mov.nombre,
                          tipo: mov.tipo,
                          poder_base: mov.poder_base
                        }
                      end)
                  }
                }
              end)
              |> Map.new(),

            sobres_pendientes:
              Enum.map(datos.sobres_pendientes, fn {id, sobre} ->
                {
                  id,
                  %{
                    tipo: sobre.tipo
                  }
                }
              end)
              |> Map.new(),

            equipos:
              Enum.map(datos.equipos, fn {nombre,equipo} ->
                {
                  nombre,
                  %{
                    pokemones: equipo.pokemones
                  }
                }
              end)
              |> Map.new()
          }
        }
      end)
      |> Map.new()
      |> Jason.encode!(pretty: true)

    File.write("data/trainers.json", json)
  end

end
