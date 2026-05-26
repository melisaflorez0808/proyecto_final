defmodule Batalla do

  use GenServer
  @tiempo_turno 60000
  @nodo_servidor :servidor@localhost

  def start_link({id_sala, creador, pid_creador, pokemon_activo, equipo_creador}) do
    GenServer.start_link(__MODULE__, {id_sala, creador, pid_creador, pokemon_activo, equipo_creador})
  end

  @impl true
  def init({id_sala, creador, pid_creador, pokemon_activo, equipo_creador}) do

    Process.send_after(self(), {:timeout_sala, id_sala}, 120000)

    estado = %{
      id_sala: id_sala,
      estado: :esperando,

      turno: 1,
      tiempo_turno: @tiempo_turno,

      creador: creador,
      pid_creador: pid_creador,
      equipo_creador: equipo_creador,
      pokemon_activo_creador: pokemon_activo,

      contrincante: nil,
      pid_contrincante: nil,
      equipo_contrincante: nil,
      pokemon_activo_contrincante: nil,

      acciones: %{},
      timer_turno: nil
    }
    send(estado.pid_creador, {:sala_creada, id_sala})
    {:ok,estado}
  end

  @impl true
  def handle_call({:unirse_sala_batalla, usuario, pid_contrincante, equipo_batalla, pokemon_activo},_from, estado) do

    if (estado.contrincante != nil) do
      {:reply, {:error,:participantes_completos}, estado}
    else
      Process.monitor(pid_contrincante)
      nuevo_estado = %{
        estado |
        contrincante: usuario,
        pid_contrincante: pid_contrincante,
        equipo_contrincante: equipo_batalla,
        pokemon_activo_contrincante: pokemon_activo
      }
      mensaje = "[Sala #{estado.id_sala}] #{usuario} Se ha Unido"
      #Aviso a Ambos
      send(estado.pid_creador, {:unido_sala, mensaje})
      send(pid_contrincante, {:unido_sala, mensaje})
      send(self(), :habilitar_batalla)
      {:reply, {:ok, mensaje}, nuevo_estado}
    end
  end

  #---------------Acciones de la Batalla-----------------------------

  #==== Iniciamos la Batalla ====
  @impl true
  def handle_info(:habilitar_batalla, estado) do
     IO.inspect(estado.tiempo_turno, label: "TIEMPO TURNO")
    Util.imprimir_mensaje("check")
    #Habilito la Escucha de Batalla
    send(estado.pid_creador, {:batalla_iniciada})
    send(estado.pid_contrincante, {:batalla_iniciada})

    #Iniciamos Tiempo Turno
    timer = Process.send_after(self(), :timeout_turno, estado.tiempo_turno)

    #Actualizo la Referencia del Timer Turno (para luego deshabilitarla)
    nuevo_estado = %{ estado | estado: :combate, timer_turno: timer}
    enviar_estado_turno(nuevo_estado)
    {:noreply, nuevo_estado}
  end

  #========== Recibir Acciones del Entrenador y Mandar A Ejecutar ==========
  @impl true
  def handle_cast({:accion, pid, accion}, estado) do

    #Guardo las Acciones de Cada Entrenador
    acciones_actualizadas = Map.put(estado.acciones, pid, accion)
    nuevo_estado = %{estado | acciones: acciones_actualizadas}

    #Si recibe la acción de ambos jugadores, resuelve el turno
    if map_size(acciones_actualizadas) == 2 do
      resolver_turno(nuevo_estado)
    else
      {:noreply, nuevo_estado}
    end
  end

  #==== Control Tiempo Turno ====
  @impl true
  def handle_info(:timeout_turno, estado) do
    #Si terminó el turno y no hay acciones, pasa
    acciones =
      estado.acciones
      |> agregar_pasar_si_falta(estado.pid_creador)
      |> agregar_pasar_si_falta(estado.pid_contrincante)

    nuevo_estado = %{estado | acciones: acciones}
    resolver_turno(nuevo_estado)
  end

  #==== Control Tiempo Unirse a Sala ====
  @impl true
  def handle_info({:timeout_sala, id_sala}, estado) do
    if estado.contrincante == nil do
      send(estado.pid_creador, {:sala_cancelada, id_sala})
      {:stop, :normal, estado}
    else
      {:noreply, estado}
    end
  end

  #=== Desconexiones ===

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, estado) do
    cond do
      pid == estado.pid_creador ->
        send(estado.pid_contrincante, {:ganador, "El Rival se Desconectó"})
        {:stop, :normal, estado}

      pid == estado.pid_contrincante ->
        send(estado.pid_creador, {:ganador, "El Rival se Desconectó"})
        {:stop, :normal, estado}
      true ->
        {:noreply, estado}
    end
  end

  #======================== Resolver Turno ===========================
  defp resolver_turno(estado) do

    #Cancelo el Timer para luego reiniciarlo (incluye acciones o si pasaron)
    Process.cancel_timer(estado.timer_turno)

    accion_creador = Map.get(estado.acciones, estado.pid_creador )
    accion_contrincante = Map.get(estado.acciones, estado.pid_contrincante)

    #Obtengo los Pokemones del Turno Según Su Id
    pokemon_creador =
      obtener_pokemon_activo(estado.equipo_creador, estado.pokemon_activo_creador)

    pokemon_contrincante =
      obtener_pokemon_activo(estado.equipo_contrincante, estado.pokemon_activo_contrincante)

    #Lista de Orden de Acción (quien hace primero)
    orden =
      MotorCombate.orden_por_velocidad(
        {:creador, pokemon_creador.velocidad},
        {:contrincante, pokemon_contrincante.velocidad}
      )

    #Realizo Los Ataques y/o Acciones del Turno
    {estado_despues, mensajes} =
      ejecutar_acciones(orden, accion_creador, accion_contrincante, estado)

    mensaje_turno = Enum.join(mensajes, "\n")
    send(estado.pid_creador, {:resultado_turno, mensaje_turno})
    send(estado.pid_contrincante, {:resultado_turno, mensaje_turno})

    cond do

      equipo_debilitado?(estado_despues.equipo_creador) ->

        GenServer.cast({Servidor, @nodo_servidor}, {:recompensa, estado.pid_contrincante, 100})
        GenServer.cast({Servidor, @nodo_servidor}, {:recompensa, estado.pid_creador, 30})
        send(estado.pid_contrincante, {:ganador, "¡Ganaste la Batalla. Recibes 100 Monedas!"})
        send(estado.pid_creador, {:perdedor, "Perdiste la Batalla. Recibes 30 Monedas"})
        LoggerBatallas.guardar_batalla(self(), estado.creador, estado.contrincante)
        {:stop, :normal, estado_despues}

      equipo_debilitado?(estado_despues.equipo_contrincante) ->

        GenServer.cast({Servidor, @nodo_servidor}, {:recompensa, estado.pid_creador, 100})
        GenServer.cast({Servidor, @nodo_servidor}, {:recompensa, estado.pid_contrincante, 30})
        send(estado.pid_creador, {:ganador, "¡Ganaste la Batalla. Recibes 100 Monedas!"})
        send(estado.pid_contrincante, {:perdedor, "Perdiste la Batalla. Recibes 30 Monedas"})
        LoggerBatallas.guardar_batalla(self(), estado.creador, estado.contrincante)
        {:stop, :normal, estado_despues}

      #Si aún pueden batallar
      true ->
        timer = Process.send_after(self(), :timeout_turno, estado.tiempo_turno)

        nuevo_estado = %{
          estado_despues |
          turno: estado.turno + 1,
          acciones: %{},
          timer_turno: timer
        }

        enviar_estado_turno(nuevo_estado)
        {:noreply, nuevo_estado}
    end
  end

  defp enviar_estado_turno(estado) do

    mensaje_creador =
      MotorCombate.visualizar_turno(
        estado.turno,
        estado.pokemon_activo_contrincante,
        estado.equipo_contrincante,
        estado.pokemon_activo_creador,
        estado.equipo_creador
      )

    mensaje_contrincante =
      MotorCombate.visualizar_turno(
        estado.turno,
        estado.pokemon_activo_creador,
        estado.equipo_creador,
        estado.pokemon_activo_contrincante,
        estado.equipo_contrincante
      )

    send(estado.pid_creador, {:turno, estado.turno, mensaje_creador})
    send(estado.pid_contrincante,{:turno, estado.turno, mensaje_contrincante})
  end

  defp ejecutar_acciones([primero, segundo], accion_creador, accion_contrincante, estado) do

    acciones = %{creador: accion_creador, contrincante: accion_contrincante}

    {estado_1, mensajes_1} = ejecutar_accion(primero, Map.get(acciones, primero), estado)

    rival_vivo =

      case segundo do

        :creador ->
          pokemon_vivo?(estado_1.equipo_creador, estado_1.pokemon_activo_creador)

        :contrincante ->
          pokemon_vivo?(estado_1.equipo_contrincante, estado_1.pokemon_activo_contrincante)
      end

    if rival_vivo do
      {estado_2, mensajes_2} = ejecutar_accion(segundo, Map.get(acciones, segundo), estado_1)

      {estado_2, mensajes_1 ++ mensajes_2}

    else
      {estado_1, mensajes_1}
    end
  end

  #Llega tipo de Jugador :creador - :contrincante, la accion y el estado
  defp ejecutar_accion(jugador, accion, estado) do

    cond do

      accion == :pasar -> {estado, ["#{jugador} No Hizo Nada"]}

      #Miro si es un ataque
      String.starts_with?(accion, "ataque") -> ejecutar_ataque(jugador, accion, estado)

      String.starts_with?(accion, "cambiar") -> ejecutar_cambio(jugador, accion, estado)

      accion == "rendirse" -> ejecutar_rendicion(jugador, estado)

      true -> {estado, ["Acción Inválida"]}
    end
  end

  defp ejecutar_cambio(jugador, accion, estado) do
    [_cmd, id_pokemon] = String.split(accion, " ", parts: 2)

    cond do

      jugador == :creador ->

        pokemon = Map.get(estado.equipo_creador, id_pokemon)

        cond do

          pokemon == nil -> {estado, ["Pokémon Inválido"]}

          pokemon.salud <= 0 -> {estado, ["Ese Pokémon Está Debilitado"]}

          true ->
            nuevo_estado = %{ estado | pokemon_activo_creador: id_pokemon}
            {nuevo_estado, ["Cambio exitoso a #{pokemon.especie}"]}
        end

      true ->

        pokemon = Map.get(estado.equipo_contrincante, id_pokemon)

        cond do

          pokemon == nil -> {estado, ["Pokémon Inválido"]}

          pokemon.salud <= 0 -> {estado, ["Ese Pokémon Está Debilitado"]}

          true ->
            nuevo_estado = %{ estado | pokemon_activo_contrincante: id_pokemon}
            {nuevo_estado, ["Cambio Exitoso a #{pokemon.especie}"]}
        end
    end
  end

  #==================== Ataque ====================

  defp ejecutar_ataque(jugador, accion, estado) do

    #Separamos en Máximo Dos Partes (parts: 2) Para el caso en que existan más de dos espacios
    #y obtengo el nombre del movimiento
    [_ataque, nombre_movimiento] = String.split(accion, " ", parts: 2)

    #Quien ataque y quien recibe el ataque para calcular daño
    {pokemon_atacante, pokemon_defensor} =
      if jugador == :creador do
        {obtener_pokemon_activo(
          estado.equipo_creador, estado.pokemon_activo_creador),
          obtener_pokemon_activo(
            estado.equipo_contrincante,
            estado.pokemon_activo_contrincante
          )
        }
      else
        {obtener_pokemon_activo(
          estado.equipo_contrincante,estado.pokemon_activo_contrincante),
          obtener_pokemon_activo(
            estado.equipo_creador,
            estado.pokemon_activo_creador
          )
        }
      end

    #Busco que coincida con el nombre del movimiento (ataque)
    movimiento =
      Enum.find(pokemon_atacante.movimientos, fn mov ->
        String.downcase(mov.nombre) == String.downcase(nombre_movimiento)
      end)

    if movimiento == nil do
      {estado, ["Movimiento Inválido"]}

    else
      dano =
        MotorCombate.calcular_dano(
          movimiento.poder_base,
          pokemon_atacante.ataque,
          pokemon_defensor.defensa,
          pokemon_atacante.elemento,
          movimiento.tipo,
          pokemon_defensor.elemento
        )

      nueva_salud = max(pokemon_defensor.salud - dano, 0)

      pokemon_actualizado = %{pokemon_defensor | salud: nueva_salud}

      estado_actualizado =
        actualizar_pokemon_defensor(jugador, pokemon_actualizado, estado)

      mensaje =
        """

        #{pokemon_atacante.especie} Usó #{movimiento.nombre} e Hizo #{dano} de Daño
        """

      if nueva_salud <= 0 do

        {estado_final, mensaje_cambio} =
          cambiar_pokemon_debilitado(jugador, estado_actualizado)

        {estado_final,
          [mensaje,"#{pokemon_defensor.especie} Fue Debilitado", mensaje_cambio]}

      else
        {estado_actualizado, [mensaje]}
      end
    end
  end

  defp cambiar_pokemon_debilitado(jugador, estado) do

    if jugador == :creador do

      equipo = estado.equipo_contrincante

      pokemon_disponible =
        Enum.find(equipo, fn {_id, pokemon} -> pokemon.salud > 0 end)

      case pokemon_disponible do

        nil ->
          {estado, "No Quedan Pokémon Disponibles"}

        {id, pokemon} ->

          nuevo_estado = %{estado | pokemon_activo_contrincante: id}

          {nuevo_estado, "El Rival Envió a #{pokemon.especie}"}
      end

    else

      equipo = estado.equipo_creador

      pokemon_disponible =
        Enum.find(equipo, fn {_id, pokemon} -> pokemon.salud > 0 end)

      case pokemon_disponible do

        nil ->
          {estado, "No Quedan Pokémon Disponibles"}

        {id, pokemon} ->

          nuevo_estado = %{ estado | pokemon_activo_creador: id}

          {nuevo_estado, "El Entrenador Envió a #{pokemon.especie}"}
      end
    end
  end

  #================== Extras =====================
  #Pokemon Activo en Batalla
  defp obtener_pokemon_activo(equipo, id_activo) do
    Map.get(equipo, id_activo)
  end

  #Verificar si un Pokemon está vivo
  defp pokemon_vivo?(equipo, id) do
    pokemon = Map.get(equipo, id)
    pokemon.salud > 0
  end

  #Verificar si todo el equipo murió para terminar batalla
  defp equipo_debilitado?(equipo) do
    Enum.all?(equipo, fn {_id, pokemon} -> pokemon.salud <= 0 end)
  end


  defp actualizar_pokemon_defensor(jugador, pokemon_actualizado, estado) do

    if jugador == :creador do

      equipo_actualizado =
        Map.put(estado.equipo_contrincante, pokemon_actualizado.id, pokemon_actualizado)

      %{estado | equipo_contrincante: equipo_actualizado}

    else
      equipo_actualizado =
        Map.put(estado.equipo_creador, pokemon_actualizado.id, pokemon_actualizado)

      %{estado | equipo_creador: equipo_actualizado}
    end
  end

  defp agregar_pasar_si_falta(acciones, pid) do
    if Map.has_key?(acciones, pid) do
      acciones
    else
      Map.put(acciones, pid, :pasar)
    end
  end

  #================== Rendirse =====================

  defp ejecutar_rendicion(jugador, estado) do

    if jugador == :creador do
      send(estado.pid_contrincante, {:ganador, "El Rival se Rindió"})
      send(estado.pid_creador, {:perdedor, "Te Rendiste"})

    else
      send(estado.pid_creador, {:ganador, "El Rival se Rindió"})
      send(estado.pid_contrincante, {:perdedor, "Te Rendiste"})
    end
    {:stop, :normal, estado}
  end

end
