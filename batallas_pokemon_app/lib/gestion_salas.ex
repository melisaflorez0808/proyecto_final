defmodule GestionSalas do

  def crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios) do
    id_sala = generar_id()

    if Map.has_key?(intercambios,id_sala) do
      crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios)
    else
      usuario_en_sala =
        Enum.any?(intercambios, fn {_codigo, sala} ->
          sala.pid_creador == pid_usuario or
          sala.pid_invitado == pid_usuario end)

      cond do
        usuario_en_sala ->
          {:error,:usuario_sala_intercambios}

        true->
          {:ok,pid_sala}=DynamicSupervisor.start_child(supervisor,{Intercambio,{id_sala,usuario,pid_usuario}})
          nueva_sala = %{
            pid_sala: pid_sala,
            pid_creador: pid_usuario,
            pid_invitado: nil
          }

          intercambios_actualizados = Map.put(intercambios, id_sala, nueva_sala)

          {:ok,{intercambios_actualizados,id_sala,pid_sala}}
        end
    end
  end

  def crear_sala_batalla(pid_usuario, usuario, pokemon_activo, equipo_batalla, supervisor, batallas) do

    id_sala = generar_id()

    if Map.has_key?(batallas, id_sala) do
      crear_sala_batalla(pid_usuario, usuario, pokemon_activo, equipo_batalla, supervisor, batallas)
    else
      {:ok, pid} = DynamicSupervisor.start_child(supervisor, {Batalla,{id_sala, usuario, pid_usuario, pokemon_activo, equipo_batalla}})
      batallas_actualizadas = Map.put(batallas, id_sala, %{pid_sala: pid, usuarios: [pid_usuario]})

      {:ok, {batallas_actualizadas, id_sala, pid}}
    end
  end

  def generar_id do
    :crypto.strong_rand_bytes(4) |> Base.encode16()
  end

end
