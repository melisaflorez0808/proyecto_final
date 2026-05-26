defmodule Intercambio do
  use GenServer

  def start_link({id_sala,creador,pid_creador}) do
    GenServer.start_link(__MODULE__, {id_sala,creador,pid_creador})
  end

  @impl true
  def init({id_sala,creador,pid_creador}) do

    Process.send_after(self(), {:timeout_sala, id_sala}, 40000)
    ref = Process.monitor(pid_creador)

    estado= %{
      id_sala: id_sala,
      pid_creador: pid_creador,
      creador: creador,
      pid_invitado: nil,
      invitado: nil,
      pokemon_creador: nil,
      pokemon_invitado: nil,
      confirmo_creador: false,
      confirmo_invitado: false,
      referencias: %{pid_creador => ref},
    }

    send(estado.pid_creador,{:sala_creada, id_sala})
    {:ok,estado}
  end

  @impl true
  def handle_call({:unirse_sala_intercambio, invitado,pid_invitado},_from, estado) do
    cond do
      invitado==estado.creador ->
        {:reply,{:error,:misma_persona},estado}

      (estado.invitado != nil) ->
        {:reply,{:error,:participantes_completos},estado}

      true ->
        ref=Process.monitor(pid_invitado)
        nuevo_estado=%{estado|pid_invitado: pid_invitado, invitado: invitado, referencias: Map.put(estado.referencias,pid_invitado,ref)}
        mensaje="[Sala #{nuevo_estado.id_sala}] #{invitado} se ha unido. Ya pueden intercambiar"

        send(nuevo_estado.pid_creador, {:unido_sala, mensaje})

        mensaje_opciones="""
        ----------------------------------------------------
        [Sala #{nuevo_estado.id_sala}]

        #{nuevo_estado.creador} y #{nuevo_estado.invitado} estan en sala.
        Utilicen los siguientes comandos según lo requieran:
        ofrecer_pokemon <id_pokemon>
        confirmar_intercambio
        cancelar_intercambio
        [Escriba reset para refrescar la pantalla]
        ----------------------------------------------------
        """

        send(nuevo_estado.pid_creador,{:opciones,mensaje_opciones,nuevo_estado.id_sala})
        send(nuevo_estado.pid_invitado,{:opciones,mensaje_opciones,nuevo_estado.id_sala})

        {:reply, {:ok,mensaje}, nuevo_estado}
      end
    end

  @impl true
  def handle_call({:ofrecer_pokemon,pid_usuario,pokemon_intercambiar,elementos},_from, estado) do
    elemento=
      Enum.map(elementos, fn elemento -> "#{elemento}" end)
      |>Enum.join("/")
    mensaje=
      "ofrece [#{pokemon_intercambiar.id}] #{pokemon_intercambiar.especie} (#{elemento}, #{pokemon_intercambiar.rareza}, Dueño original: #{pokemon_intercambiar.dueno_original})"

    if pokemon_intercambiar != nil do
      {nuevo_estado,mensaje_respuesta}=
        cond do
          pid_usuario == estado.pid_creador ->
            nuevo_estado=%{estado|pokemon_creador: pokemon_intercambiar, confirmo_creador: false, confirmo_invitado: false}
            mensaje_enviar="[Sala #{estado.id_sala}] #{estado.creador} #{mensaje}"
            send(estado.pid_invitado, {:ofrecimiento,mensaje_enviar})
            {nuevo_estado,mensaje_enviar}

          pid_usuario == estado.pid_invitado ->
            nuevo_estado=%{estado|pokemon_invitado: pokemon_intercambiar, confirmo_invitado: false, confirmo_creador: false}
            mensaje_enviar="[Sala #{estado.id_sala}] #{estado.invitado} #{mensaje}"
            send(estado.pid_creador,{:ofrecimiento,mensaje_enviar})
            {nuevo_estado,mensaje_enviar}

          true ->
            {estado,nil}
        end

      if nuevo_estado.pokemon_creador !=nil and nuevo_estado.pokemon_invitado !=nil do
        mensaje="""
        ----------------------------------------------------
        [Sala #{nuevo_estado.id_sala}]

        #{nuevo_estado.creador} -> [#{nuevo_estado.pokemon_creador.id}] #{nuevo_estado.pokemon_creador.especie}
        #{nuevo_estado.invitado} -> [#{nuevo_estado.pokemon_invitado.id}] #{nuevo_estado.pokemon_invitado.especie}
        Ambos han ofrecido. Confirma con: confirmar_intercambio

        Aún puede usar:
        ofrecer_pokemon <id_pokemon>
        cancelar_intercambio
        [Escriba reset para refrescar la pantalla]
        ----------------------------------------------------
        """
        send(nuevo_estado.pid_creador,{:opciones,mensaje,nuevo_estado.id_sala})
        send(nuevo_estado.pid_invitado,{:opciones,mensaje,nuevo_estado.id_sala})
      end

      {:reply, {:ok,mensaje_respuesta}, nuevo_estado}

    else
      {:reply, {:error,"No se pudo completar operacion"},estado}
    end
  end

  @impl true
  def handle_call({:confirmar_intercambio,pid_usuario},_from, estado) do

    mensaje= "[Sala #{estado.id_sala}] Confirmaste tu intercambio... Espera a la confirmación del otro entrenador..."

    cond do
      pid_usuario == estado.pid_creador->
        cond do
          estado.confirmo_creador ->
            {:reply, {:error, "Ya confirmaste el intercambio"}, estado}

          estado.pokemon_creador ==nil ->
            {:reply, {:error,"#{estado.creador}: No ofrecio pokemon para intercambio\n"}, estado}

          true ->
            nuevo_estado=%{estado|confirmo_creador: true}
            send(self(),:verificar_confirmacion)
            {:reply, {:ok,mensaje}, nuevo_estado}
        end

      pid_usuario==estado.pid_invitado ->
        cond do
          estado.confirmo_invitado ->
            {:reply, {:error, "Ya confirmaste el intercambio"}, estado}

          estado.pokemon_invitado ==nil ->
            {:reply, {:error,"#{estado.invitado}: No ofrecio pokemon para intercambio\n"}, estado}

          true ->
            nuevo_estado=%{estado|confirmo_invitado: true}
            send(self(),:verificar_confirmacion)
            {:reply, {:ok,mensaje}, nuevo_estado}
        end

      true ->
        {:reply, {:error,"No se pudo confirmar intercambio"}, estado}
      end
    end

  @impl true
  def handle_info(:cancelar_intercambio, estado) do

    send(estado.pid_creador,{:sala_cancelada, estado.id_sala})
    if estado.pid_invitado != nil do
      send(estado.pid_invitado,{:sala_cancelada, estado.id_sala})
    end
    notificar_servidor(estado)

    {:stop, :normal, estado}
  end

  @impl true
  def handle_info({:timeout_sala, id_sala}, estado) do
    if estado.invitado == nil do
      send(estado.pid_creador,{:sala_cancelada, id_sala})

      notificar_servidor(estado)

        {:stop, :normal, estado}
    else
      {:noreply, estado}
    end
  end

  @impl true
  def handle_info(:habilitar_interaccion_confirmacion, estado) do
    mensaje="""
    ----------------------------------------------------
    [Sala #{estado.id_sala}]

    #{estado.creador} -> [#{estado.pokemon_creador.id}] #{estado.pokemon_creador.especie}
    #{estado.invitado} -> [#{estado.pokemon_invitado.id}] #{estado.pokemon_invitado.especie}
    Ambos han ofrecido. Confirma con: confirmar_intercambio

    Aún puede usar:
    ofrecer_pokemon <id_pokemon>
    cancelar_intercambio
    [Escriba reset para refrescar la pantalla]
    ----------------------------------------------------
    """
    send(estado.pid_creador,{:opciones,mensaje,estado.id_sala})
    send(estado.pid_invitado,{:opciones,mensaje,estado.id_sala})

    {:noreply, estado}

  end

  @impl true
  def handle_info(:verificar_confirmacion, estado) do
    if estado.confirmo_creador and estado.confirmo_invitado do
      resultado = %{
        id_sala: estado.id_sala,
        creador_recibe: estado.pokemon_invitado,
        invitado_recibe: estado.pokemon_creador,
        pid_creador: estado.pid_creador,
        pid_invitado: estado.pid_invitado}

        mensaje_creador="""
        [Intercambio completado]
        Recibiste [#{estado.pokemon_invitado.id}] #{estado.pokemon_invitado.especie}.
        #{estado.invitado} recibió [#{estado.pokemon_creador.id}] #{estado.pokemon_creador.especie}.
        """
        mensaje_invitado="""
        [Intercambio completado]
        Recibiste [#{estado.pokemon_creador.id}] #{estado.pokemon_creador.especie}.
        #{estado.creador} recibió [#{estado.pokemon_invitado.id}] #{estado.pokemon_invitado.especie}.
        """

        send(estado.pid_creador, {:intercambio_completado, mensaje_creador})
        send(estado.pid_invitado, {:intercambio_completado, mensaje_invitado})

        GenServer.cast({Servidor, :servidor@localhost},{:finalizar_intercambio, resultado})

        {:stop, :normal, estado}
    else
      {:noreply, estado}
    end

  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, estado) do
    if pid == estado.pid_creador or pid == estado.pid_invitado do
      cond do
        pid == estado.pid_creador ->
          if estado.pid_invitado != nil do
            send(estado.pid_invitado, {:sala_cancelada, estado.id_sala})
          end
          notificar_servidor(estado)
          {:stop, :normal, estado}

        pid== estado.pid_invitado ->
          send(estado.pid_creador, {:sala_cancelada, estado.id_sala})
          notificar_servidor(estado)
          {:stop, :normal, estado}

        true ->
          {:noreply, estado}
      end
    else
      {:noreply, estado}
    end
  end

  def notificar_servidor(estado) do
    send({Servidor, :servidor@localhost},{
      :sala_intercambio_finalizada,
      estado.id_sala,
      estado.pid_creador,
      estado.pid_invitado})
  end

end
