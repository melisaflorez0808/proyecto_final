defmodule GestionSalas do

  def crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios) do

    id_sala = generar_id()

    if Map.has_key?(intercambios,id_sala) do
      crear_sala_intercambios(pid_usuario,usuario,supervisor,intercambios)
    else

      {:ok,pid} = DynamicSupervisor.start_child(supervisor,{Intercambio,{id_sala,usuario,pid_usuario}})

      intercambios_actualizados = Map.put(intercambios, id_sala, pid)

      {:ok,{intercambios_actualizados,id_sala,pid}}
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
