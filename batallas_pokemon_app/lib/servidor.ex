defmodule Servidor do

  use GenServer

  def main do

    IO.puts("Servidor iniciando....")
    {:ok, _} = Node.start(:servidor@localhost, :shortnames)
    Node.set_cookie(:pokemon)
    {:ok, _} = start_link()
    IO.puts("El servidor se ha iniciado!")
    Process.sleep(:infinity)
  end


  def start_link() do
    GenServer.start_link(_MODULE, nil, name: __MODULE_)
  end


  @impl true
  def init(_) do

     {:ok, supervisor} = DynamicSupervisor.start_link(strategy: :one_for_one)

    estado = %{
      pokemones: Persistencia.leer_pokemones(),
      movimientos: Persistencia.leer_movimientos(),
      entrenadores: Persistencia.leer_entrenadores(),
      tienda: Persistencia.leer_tienda(),
      sesiones: %{},
      supervisor: supervisor,
      batallas: %{},
      intercambios: %{}
    }

    IO.puts("Servidor iniciado correctamente")
    IO.inspect(estado.entrenadores)
    IO.inspect(estado.pokemones)
    IO.inspect(estado.tienda)
    IO.inspect(estado.movimientos)

    {:ok, estado}
  end

  #-------------------- Login ---------------------------------------
  @impl true
  def handle_call({:login, usuario, clave, pid}, _from, estado) do

    case Map.get(estado.entrenadores, usuario) do
      nil ->
        id = UUID.uuid4()
        nuevo = %Entrenador{
          clave: clave,
          sobres_pendientes: %{
            id => %SobrePendiente{tipo: "basico"}
          }
        }
        entrenadores_actualizados =
          Map.put(estado.entrenadores, usuario, nuevo)

        sesiones_actualizadas =
          Map.put(estado.sesiones, pid, usuario)

        nuevo_estado = %{
          estado
          | entrenadores: entrenadores_actualizados,
            sesiones: sesiones_actualizadas
        }

        IO.inspect(nuevo_estado.sesiones, label: "Sesiones en Servidor:\n")
        Persistencia.escribir_entrenador(entrenadores_actualizados)
        {:reply, {:ok, nuevo}, nuevo_estado}

      existente ->
        if existente.clave == clave do
            sesiones_actualizadas =
            Map.put(estado.sesiones, pid, usuario)

          nuevo_estado = %{estado | sesiones: sesiones_actualizadas}

          IO.inspect(nuevo_estado.sesiones, label: "Sesiones en Servidor:\n")
          {:reply, {:ok, :existente}, nuevo_estado}

        else
          {:reply, {:error, :clave_incorrecta}, estado}
        end
    end
  end

  #-------------------- Logout ---------------------------------------

  @impl true
  def handle_call({:logout, pid}, _from, estado) do

    case Map.get(estado.sesiones, pid) do
      nil ->
        {:reply, {:error, :usuario_no_logueado}, estado}

      _valor ->
        sesiones_actualizadas =
          Map.delete(estado.sesiones,pid)

          nuevo_estado = %{estado | sesiones: sesiones_actualizadas}

          IO.inspect(nuevo_estado.sesiones, label: "Sesiones en Servidor:\n")
          {:reply,{:ok,:finalizado}, nuevo_estado}
    end
  end


  #-------------------- Perfil, Inventario y Clasificacion----------------------------------
  def handle_call({:ver_perfil,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionPerfil.ver_perfil(usuario, entrenador)
        {:reply, respuesta, estado}
    end
  end

  def handle_call({:ver_inventario,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionPerfil.ver_inventario(usuario, entrenador, estado)
        {:reply, respuesta, estado}
    end
  end

  def handle_call({:ver_equipos,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionEquipos.listar_equipos(entrenador)
        {:reply, respuesta, estado}
    end
  end

  def handle_call({:generar_clasificacion,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      _entrenador ->
        respuesta = GestionPerfil.generar_clasificacion(estado.entrenadores)
        {:reply, respuesta, estado}
    end
  end

  #-------------------- Tienda y Sobres-----------------------------------
  @impl true
  def handle_call({:ver_tienda, pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      _entrenador ->
        respuesta = GestionTienda.ver_tienda(estado.tienda)
        {:reply, respuesta, estado}
    end
  end

  @impl true
  def handle_call({:comprar_sobre, pid, tipo_sobre}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, {:error, "Entrenador No Encontrado"}, estado}

      entrenador ->
        case GestionTienda.comprar_sobre(entrenador, tipo_sobre, estado.tienda) do
          {:ok, monedas} ->

            id = UUID.uuid4()

            sobres_actualizados =
              Map.put(entrenador.sobres_pendientes, id, %SobrePendiente{tipo: tipo_sobre})

            nuevo =
              %{
                entrenador
                | monedas_actuales: monedas,
                  sobres_pendientes: sobres_actualizados
              }

            entrenadores_actualizados =
              Map.put(estado.entrenadores, usuario, nuevo)

            nuevo_estado = %{
              estado
              | entrenadores: entrenadores_actualizados
            }

            Persistencia.escribir_entrenador(entrenadores_actualizados)
            {:reply, {:ok, "Nuevo Sobre Tipo -#{tipo_sobre}- Agregado a Sobres Pendientes"}, nuevo_estado}

          {:error, _razon} ->
            {:reply, {:error, "Monedas Insuficientes Para Realizar la Compra"}, estado}
        end
    end
  end

  @impl true
  def handle_call({:ver_sobres, pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, {:error, "Usuario No Encontrado"}, estado}

      entrenador ->
        mensaje = GestionTienda.ver_sobres_pendientes(entrenador)
        {:reply, {:ok, mensaje}, estado}
    end
  end

  @impl true
  def handle_call({:abrir_sobre, pid, id_sobre}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, {:error, "Usuario No Encontrado"}, estado}

      entrenador ->
        case GestionTienda.abrir_sobre(usuario, estado, entrenador, id_sobre) do

          {:error, razon} ->
            {:reply, {:error, razon}, estado}

          {:ok, pokemones, mensaje} ->

            nuevo_inventario =
              Enum.reduce(pokemones, entrenador.inventario, fn {id, pokemon}, acc ->
                Map.put(acc, id, pokemon)
              end)

            sobres_actualizados = Map.delete(entrenador.sobres_pendientes, id_sobre)

            entrenador_actualizado =
              %{
                entrenador
                | inventario: nuevo_inventario,
                  sobres_pendientes: sobres_actualizados
              }

            entrenadores_actualizados =
              Map.put(estado.entrenadores, usuario, entrenador_actualizado)

            nuevo_estado =
              %{estado | entrenadores: entrenadores_actualizados}

            Persistencia.escribir_entrenador(entrenadores_actualizados)
            {:reply, {:ok, mensaje}, nuevo_estado}
        end
    end
  end

  #------------------ Intercambio Pokemon---------------------------------

  @impl true
  def handle_call({:crear_sala_intercambio, pid_usuario}, _from, estado) do

    usuario=Map.get(estado.sesiones,pid_usuario)

    case GestionSalas.crear_sala_intercambios(pid_usuario,usuario,estado.supervisor,estado.intercambios) do

      {:ok,{intercambios_actualizados,id_sala,pid}} ->

        Process.monitor(pid)

        nuevo_estado=%{estado | intercambios: intercambios_actualizados}

        {:reply, "Sala creada con id: #{id_sala}", nuevo_estado}

    end
  end






  #----------------------- Equipos Pokemon -------------------------------
  def handle_call({:crear_equipo,nombre,ids,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    entrenador=estado.entrenadores[usuario]

    case GestionEquipos.crear_equipo(nombre,ids,entrenador) do

      {:equipo_creado,entrenador_actualizado} ->
        entrenadores_actualizados=Map.put(estado.entrenadores,usuario,entrenador_actualizado)
        nuevo_estado=%{estado | entrenadores: entrenadores_actualizados}
        Persistencia.escribir_entrenador(nuevo_estado.entrenadores)

        {:reply, "Equipo creado", nuevo_estado}

      {:error, :nombre_equipo_duplicado} ->
        {:reply, "El nombre del equipo ya existe", estado}

      {:error,razon} ->
        {:reply, razon, estado}
    end
  end

  def handle_call({:quitar_pokemon_equipo,nombre_equipo,id_pokemon,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    entrenador=estado.entrenadores[usuario]

    case GestionEquipos.quitar_pokemon_equipo(nombre_equipo,id_pokemon,entrenador) do

      {:pokemon_eliminado,entrenador_actualizado} ->
        entrenadores_actualizados=Map.put(estado.entrenadores,usuario,entrenador_actualizado)
        nuevo_estado=%{estado | entrenadores: entrenadores_actualizados}
        Persistencia.escribir_entrenador(nuevo_estado.entrenadores)

        {:reply, "pokemon con #{id_pokemon} eliminado del equipo", nuevo_estado}

      {:error, razon}->
        {:reply, razon, estado}
    end
  end

  def handle_call({:agregar_pokemon_equipo,nombre_equipo,id_pokemon,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    entrenador=estado.entrenadores[usuario]

    case GestionEquipos.agregar_pokemon_equipo(nombre_equipo,id_pokemon,entrenador) do

      {:pokemon_agregado,entrenador_actualizado} ->
        entrenadores_actualizados=Map.put(estado.entrenadores,usuario,entrenador_actualizado)
        nuevo_estado=%{estado | entrenadores: entrenadores_actualizados}
        Persistencia.escribir_entrenador(nuevo_estado.entrenadores)

        {:reply, "pokemon con #{id_pokemon} agregado al equipo", nuevo_estado}

      {:error, razon}->
        {:reply, razon, estado}
    end
  end

  def handle_call({:usar_equipo,nombre_equipo,pid}, _from, estado) do
    usuario=Map.get(estado.sesiones,pid)
    entrenador=estado.entrenadores[usuario]

    case GestionEquipos.usar_equipo(nombre_equipo,entrenador) do

      {:equipo_activo,entrenador_actualizado} ->
        entrenadores_actualizados=Map.put(estado.entrenadores,usuario,entrenador_actualizado)
        nuevo_estado=%{estado | entrenadores: entrenadores_actualizados}
        Persistencia.escribir_entrenador(nuevo_estado.entrenadores)

        {:reply, "Equipo #{nombre_equipo} activo para usar en batalla", nuevo_estado}

      {:error, :equipo_pokemones_faltantes, validar} ->
        {:reply, "No se pudo usar equipo, debe quitar pokemon(es) con id: #{inspect(validar)}",estado}

      {:error, razon}->
        {:reply, razon, estado}
    end
  end

   #------------------ Salas de Batalla ---------------------------------





   #-------------------Manejo de Mensajes ----------------------------------

   @impl true

   def handle_info({:DOWN, _ref, :process, pid, _reason}, estado) do

    cond do
      Enum.any?(estado.intercambios, fn {_codigo,pid_sala} ->
        pid_sala == pid end) ->
          {id_sala, _pid_sala} =
            Enum.find(estado.intercambios, fn {_codigo,pid_sala} ->
              pid_sala == pid end)

        IO.puts("Se eliminó la sala de intercambios #{id_sala}")
        intercambios_actualizados=Map.delete(estado.intercambios,id_sala)
        nuevo_estado=%{estado | intercambios: intercambios_actualizados}
        {:noreply, nuevo_estado}

      Enum.any?(estado.batallas, fn {_codigo,pid_sala} ->
        pid_sala == pid end) ->
          {id_sala, _pid_sala} =
            Enum.find(estado.batallas, fn {_codigo,pid_sala} ->
              pid_sala == pid end)

        IO.puts("Se eliminó la sala de batallas #{id_sala}")
        batallas_actualizadas=Map.delete(estado.batallas,id_sala)
        nuevo_estado=%{estado | batallas: batallas_actualizadas}
        {:noreply, nuevo_estado}

      true ->
        {:noreply, estado}
    end
  end

end
