defmodule SistemaSobres do

  @rarezas %{"comun" => {2, 8}, "raro" => {10, 20}, "epico" => {25, 40}}

  #tipo_sobre: comun, raro, épico
  #dueno: String Usuario del entrenador
  #pokemon_map: Mapa de los pokemon base
  #moves_map: Mapa de los movimientos existentes
  #tienda_sobres: Mapa de los tipos de sobre: Básico y Avanzado (Tiene precio y probabilidad)
  def abrir_sobre_pokemon(tipo_sobre, dueno, pokemon_map, moves_map, tienda_sobres) do

    #Nombres de especies disponibles en la base de datos
    especies_ids = Map.keys(pokemon_map)

    #Extraigo las probabilidades para pokemon comun, raro y epico según el tipo de sobre (en un mapa)
    probs =
      tienda_sobres
      |> Enum.find_value(fn {tipo, sobre} -> if tipo == tipo_sobre, do: sobre.probabilidades end)

    #Si probs es nil o false devuelvo la probabilidad de un sobre básico
    probs = probs || %{"comun" => 0.7, "raro" => 0.25, "epico" => 0.05}

    #creacion de los 3 pokemon 1..3
    pokemones =

      #Mando acumulador de pokemones y la lista de ids_existentes
      Enum.map(1..3, fn _ ->

        #De la lista de nombres de Pokemon elige uno aleatorio
        especie = Enum.random(especies_ids)

        #Obtiene la especie base y le agrega el nombre del pokemon como id
        {:ok, base} = generar_especie(pokemon_map, especie)

        #Defino Rareza ("comun", "raro", "epico")
        rareza = sortear_rareza(probs)

        #Movimientos (dos del tipo del pokemos y dos al azar)
        movs = asignar_movimientos(base, moves_map)
        stats = asignar_valores_instancia( base.ataque_base, base.defensa_base, base.velocidad_base, rareza)

        id_pokemon = generar_id_unico()

        #Convertir movimientos a struct
        movimientos =
          Enum.map(movs, fn m ->
            %Movimiento{
              nombre: m.nombre,
              tipo: m.tipo,
              poder_base: m.poder_base
            }
          end)

        #Crear struct PokemonInstancia
        pokemon =
          %PokemonInstancia{
            especie: especie,
            dueno_original: dueno,
            rareza: rareza,
            ataque: stats.ataque,
            defensa: stats.defensa,
            velocidad: stats.velocidad,
            movimientos: movimientos
          }
        {id_pokemon, pokemon}

      end)
      |> Map.new()

    #Retorno Mapa de
    pokemones
  end

  def sortear_rareza(probabilidades) do

    #Elijo un Número Aleatorio entre 0 y 1
    r = :rand.uniform()

    {_acc, rareza_final} =

      #probabilidades es por ejemplo: %{"comun" => 0.7, "raro" => 0.25, "epico" => 0.05}
      probabilidades

      #Ordeno [{"comun", 0.7}, {"raro", 0.25}, {"epico", 0.05}]
      |> Enum.sort_by(fn {rareza, _valor} -> orden_rareza(rareza) end)

      #Construyo el rango 0 - 0.7 - 0.95 - 1.00
      |> Enum.reduce_while(0.0, fn {rareza, valor}, acc ->

        acc2 = acc + valor

        #halt: PARAR, #cont: SEGUIR
        if r <= acc2, do: {:halt, {acc2, rareza}}, else: {:cont, acc2}

      end)

    rareza_final
  end

  defp orden_rareza("comun"), do: 1 #los Ordeno para Crear el Rango
  defp orden_rareza("raro"), do: 2
  defp orden_rareza("epico"), do: 3
  defp orden_rareza(_), do: 0

  #Asignamos 4 movimientos según reglas sección 5.2
  def asignar_movimientos(especie_data, moves_map) do

    #Obtiene el tipo de pokemon - Como el Elemento "Fuego" o puede ser una lista si tiene más de un elemento
    tipos = especie_data.tipos

    #Obtengo la lista de mapas (o listas de structs) de acuerdo con el tipo (o tipos) que tenga el pokemon
    pools_tipo =
      Enum.map(tipos, fn tipo -> generar_movimientos_por_tipo(moves_map, tipo) end)

    elegidos =
      case tipos do
        #Si el pokemon es de un solo tipo
        [_uno] ->
          pool = List.first(pools_tipo)  # Toma la lista de movimientos del tipo, porque asi sea solo un tipo, estaba asi: [[mov1, mov2...]]
          cantidad = length(pool)        # Cuántos movimientos hay disponibles
          n = min(2, cantidad)           # min devuelve el valor más pequeño entre los dos valores que le pase
          pick_unique(pool, n)    # Devuelve una lista. De la lista selecciona el número de elementos que le pida (todos diferentes)

        #Si el pokemon es de dos tipos
        [t1, t2] ->
          p1 = generar_movimientos_por_tipo(moves_map, t1) #Movimientos Tipo 1
          p2 = generar_movimientos_por_tipo(moves_map, t2) #Movimientos Tipo 2
          a = pick_unique(p1, 1)
          b = pick_unique(p2, 1)
          a ++ b  #Junto ambas listas
      end

    #MapSet es una estructura de datos que no admite valores repetidos (así descarto repetidos)
    nombres = MapSet.new(Enum.map(elegidos, fn mov -> mov.nombre end)) #Saco la Lista de solo los nombres de los movimientos
    restantes = 4 - length(elegidos)
    complementarios = movimientos_complementarios(moves_map, nombres, restantes)
    (elegidos ++ complementarios) |> Enum.take(4)
  end

  defp movimientos_complementarios(moves_map, nombres_movs_sel, numero_movs_rest) do
    todos =
      generar_todos_movimientos(moves_map)
      |> Enum.shuffle() #Todos los movimientos que hay (mezclados aleatoriamente por el suffle)

    Enum.reduce_while(todos, {[], nombres_movs_sel}, fn mov, {acc, set} ->

      cond do

        length(acc) >= numero_movs_rest -> {:halt, {acc, set}}       #PARAR
        MapSet.member?(set, mov.nombre) -> {:cont, {acc, set}}       #Si ya existe, no agrego
        true -> {:cont, {[mov | acc], MapSet.put(set, mov.nombre)}} #Agrego

      end
    end)

    #Tomo solo el primer elemento de la tupla (el acumulador)
    |> elem(0)
    |> Enum.reverse()
  end

  def asignar_valores_instancia(ataque_base, defensa_base, velocidad_base, rareza_key) do
    f = factor_rareza_para_rango(rareza_key)
    factor = 1 + f / 100.0 #Pasamos a decimal

    %{
    ataque: round(ataque_base * factor),
    defensa: round(defensa_base * factor),
    velocidad: round(velocidad_base * factor)
    }
  end

  def factor_rareza_para_rango(rareza_key) do

    #Busco el rango según la rareza
    {li, ls} = Map.get(@rarezas, rareza_key, {2, 8})

    :rand.uniform(ls - li + 1) + li - 1 #Movemos el rango hacia arriba + lo - 1
  end                                   #Valor aleatorio entre ese rango

  defp pick_unique(pool, count) do
    pool = Enum.shuffle(pool) #Mezclo los movimientos aleatoriamente
    Enum.take(pool, min(count, length(pool))) #Tomo los primeros elementos de la lista
  end

  #Ojo, desde antes debo mandar una lista con los ids existentes
  defp generar_id_unico do
    UUID.uuid4()
  end

  def generar_especie(pokemon_map, id) do
    case Map.get(pokemon_map, id) do
      nil -> {:error, :especie_no_encontrada}
      #Si lo halla crea un mapa donde una caractaristica es el id (nombre) y las caracteristicas del pokemon
      data -> {:ok, Map.put(data, "id", id)}
    end
  end

  def generar_movimientos_por_tipo(moves_map, tipo) do
    Map.get(moves_map, tipo, [])
  end

  def generar_todos_movimientos(moves_map) do
    moves_map
    |> Map.values()   #Lista de listas (omite las claves). Son varias listas dado que son varios tipos(elementos) de pokemon
    |> List.flatten() #Lo vuelve a una sola lista
    |> Enum.uniq_by(fn mov -> mov.nombre end) #Ningun nombre repetido, y sigue siendo una lista de tuplas (cada tupla es un movimiento)
  end
end
