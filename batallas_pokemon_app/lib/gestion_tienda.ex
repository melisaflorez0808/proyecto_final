defmodule GestionTienda do

  def ver_tienda(tienda) do
    encabezado = "==== Sobres en Tienda ===="

    resto =
      tienda
      |> Enum.map(fn {tipo_sobre, sobre} ->

        probabilidades =
          sobre.probabilidades
          |> Enum.map(fn {prob, valor} ->
            "  - #{prob}: #{Float.round(valor * 100, 1)}%"
          end)
          |> Enum.join("\n")

        """
        Tipo: #{tipo_sobre}
        Precio: #{sobre.precio}
        Probabilidades:
        #{probabilidades}
        """
      end)
      |> Enum.join("\n----------------------\n")

    encabezado <> "\n\n" <> resto
  end

  def comprar_sobre(entrenador, tipo_sobre, tienda) do
    sobre = Map.get(tienda, tipo_sobre)
    valor_sobre = sobre.precio

    if entrenador.monedas_actuales >= valor_sobre do
      monedas_reales = entrenador.monedas_actuales - valor_sobre
      {:ok, monedas_reales}
    else
      {:error, "No Tiene Monedas Suficientes para Realizar la Compra"}
    end
  end

  def ver_sobres_pendientes(entrenador) do
    sobres = entrenador.sobres_pendientes

    if map_size(sobres) == 0 do
      "No tienes sobres pendientes"
    else
      encabezado = "=== Sobres Pendientes ===\n"

      cuerpo =
        sobres
        |> Enum.with_index(1)
        |> Enum.map(fn {{id, sobre}, index} ->
          "#{index}. ID: #{id} | Tipo: #{sobre.tipo}"
        end)
        |> Enum.join("\n")
      encabezado <> cuerpo
    end
  end

  def abrir_sobre(usuario, estado, entrenador, id_sobre) do
    case buscar_sobre_entrenador(entrenador, id_sobre) do
      {:error, razon} ->
        {:error, razon}

      {:ok, sobre} ->
        pokemones =
          SistemaSobres.abrir_sobre_pokemon(
            sobre.tipo,
            usuario,
            estado.pokemones,
            estado.movimientos,
            estado.tienda
          )
        mensaje = ver_pokemones(estado, pokemones)
        {:ok, pokemones, mensaje}
    end
  end

  def ver_pokemones(estado, pokemones) do

    encabezado = "¡Sobre abierto! Obtuviste:\n"

    cuerpo =
      pokemones
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

  def buscar_sobre_entrenador(entrenador, id_sobre) do
    case Map.get(entrenador.sobres_pendientes, id_sobre) do
      nil ->
        {:error, "El Entrenador No Posee ese Sobre"}
      sobre ->
        {:ok, sobre}
    end
  end
end
