defmodule GestionPerfil do

  def ver_perfil(usuario, entrenador) do
    """
    \n
    === Perfil de #{usuario} ===
    Monedas: #{entrenador.monedas_actuales}
    Sobres Pendientes: #{map_size(entrenador.sobres_pendientes)}
    Pokémon en Inventario: #{map_size(entrenador.inventario)}
    """
  end

  def ver_inventario(usuario, entrenador, estado) do
    inventario = entrenador.inventario
    total = map_size(inventario)

    encabezado = "=== Inventario de #{usuario} (#{total} Pokémon) ===\n"

    cuerpo =
      inventario
      |> Enum.with_index(1) #Mando el indice
      |> Enum.map(fn {{id, pokemon}, index} ->

        #Buscar info base (Busco por el Nombre y Obtengo al Pokemon Base)
        pokemon_base = Map.get(estado.pokemones, pokemon.especie)

        tipos =
          case pokemon_base.tipos do
            lista when is_list(lista) -> Enum.join(lista, "/") #Volver a cadena
            otro -> otro
          end

        movimientos =
          pokemon.movimientos
          |> Enum.map(fn mov ->
            "#{mov.nombre}(#{mov.poder_base})"
          end)
          |> Enum.join(", ")

        """
          #{index}. [##{id}] #{pokemon.especie} (#{tipos}) [#{pokemon.rareza}]
            Ataque: #{pokemon.ataque} | Defensa: #{pokemon.defensa} | Velocidad: #{pokemon.velocidad} | Salud máx: 100
            Dueño original: #{pokemon.dueno_original}
            Movimientos: #{movimientos}
        """
      end)
      |> Enum.join("\n")
    encabezado <> cuerpo
  end

  def generar_clasificacion(entrenadores) do
    #Para ordenar mediante sort_by por victorias debo pasar a lista
    lista =
      entrenadores
      |> Enum.map(fn {nombre, ent} ->
        {
          nombre,
          ent.victorias || 0,
          ent.monedas_acumuladas || 0
        }
      end)
      |> Enum.sort_by(fn {_nombre, victorias, _monedas} -> victorias end, :desc)

    encabezado =
    """
    ============= Clasificación Global =============
    #    Entrenador   Victorias   Monedas acumuladas
    """

    cuerpo =
      lista
      |> Enum.with_index(1)
      |> Enum.map(fn {{nombre, victorias, monedas}, posicion} ->

        monedas_formateadas = formatear_numero(monedas)

        String.pad_trailing("#{posicion}", 5) <>
        String.pad_trailing(nombre, 13) <>
        String.pad_trailing("#{victorias}", 12) <>
        monedas_formateadas
      end)
      |> Enum.join("\n")

    encabezado <> "\n" <> cuerpo
  end

  defp formatear_numero(numero) do
    numero
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/.{3}/, "\\0.")
    |> String.reverse()
    |> String.trim_leading(".")
  end
end
