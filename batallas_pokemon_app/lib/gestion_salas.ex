defmodule GestionSalas do

  def crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios) do
    id_sala = generar_id()

    if Map.has_key?(intercambios,id_sala) do
      crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios)
    else

      {:ok,pid}=DynamicSupervisor.start_child(supervisor,{Intercambio,{id_sala,usuario,pid_usuario}})

      intercambios_actualizados=Map.put(intercambios,id_sala,pid)

      {:ok,{intercambios_actualizados,id_sala,pid}}
    end
  end

  def generar_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16()
  end


  """
  @impl true
  def handle_call({:unirse_sala, id_sala, numero_invitado, pid_invitado}, _from, salas) do
    case Map.get(salas, id_sala) do
      nil ->
        {:reply, {:error, :sala_no_encontrada}, salas}

      %{numero: numero_creador, pid_creador: pid_creador, timer: timer} ->
        # Cancelar el timeout porque ya se hizo el intercambio
        Process.cancel_timer(timer)


        # Notificar al creador con el número del invitado
        send(pid_creador, {:intercambio_exitoso, numero_invitado})

        IO.puts("[Servidor] Intercambio realizado en sala {id_sala}")

        salas_actualizadas = Map.delete(salas, id_sala)
        # El invitado recibe el número del creador como respuesta
        {:reply, {:ok, numero_creador}, salas_actualizadas}
    end
  end



  """






end
