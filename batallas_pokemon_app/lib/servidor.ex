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
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
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

    usuario = Map.get(estado.sesiones, pid_usuario)

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

  def handle_call({:usar_equipo, nombre_equipo, pid}, _from, estado) do
    usuario = Map.get(estado.sesiones, pid)
    entrenador = estado.entrenadores[usuario]

    case GestionEquipos.usar_equipo(nombre_equipo, entrenador) do

      {:equipo_activo, entrenador_actualizado} ->
        entrenadores_actualizados = Map.put(estado.entrenadores,usuario,entrenador_actualizado)
        nuevo_estado = %{estado | entrenadores: entrenadores_actualizados}
        Persistencia.escribir_entrenador(nuevo_estado.entrenadores)

        {:reply, {:ok, "Equipo #{nombre_equipo} activo para usar en batalla" }, nuevo_estado}

      {:error, :equipo_pokemones_faltantes, validar} ->
        {:reply, {:error, "No se pudo usar equipo, debe quitar pokemon(es) con id: #{IO.inspect(validar)}"}, estado}

      {:error, razon}->
        {:reply, {:error, razon}, estado}
    end
  end

   #------------------ Salas de Batalla ---------------------------------

  #*****MODIFICADA
  @impl true
  def handle_call({:crear_sala_batalla, pid_usuario, pokemon_inicial}, _from, estado) do

    usuario = Map.get(estado.sesiones, pid_usuario)
    entrenador = Map.get(estado.entrenadores, usuario)

    case preparar_equipo_batalla(pid_usuario, estado) do
      {:error, razon} ->
        {:reply, {:error, razon}, estado}

      {:sin_equipo_activo, _entrenador} ->
        {:reply, {:error, "No tienes equipo activo"}, estado}

        {:ok, entrenador} ->

          case GestionEquipos.armar_equipo_batalla(estado.pokemones, entrenador, pokemon_inicial) do

            {:error, razon} ->
              {:reply, {:error, razon}, estado}

            {:ok, equipo_batalla, pokemon_activo} ->

              case GestionSalas.crear_sala_batalla(pid_usuario, usuario, pokemon_activo, equipo_batalla, estado.supervisor, estado.batallas) do

                {:ok, {batallas_actualizadas, id_sala, pid_sala}} ->
                  Process.monitor(pid_sala)
                  nuevo_estado = %{ estado | batallas: batallas_actualizadas}
                  {:reply, {:ok, "Sala creada con id #{id_sala}. Esperando que Alguien se Una...", pid_sala}, nuevo_estado}
              end
      end
    end
  end

  #*****MODIFICADA
  defp preparar_equipo_batalla(pid_usuario, estado) do
    usuario = Map.get(estado.sesiones, pid_usuario)
    entrenador = Map.get(estado.entrenadores, usuario)

    cond do
      entrenador == nil ->
        {:error, "Entrenador no encontrado"}

      entrenador.equipo_activo == nil ->
        {:sin_equipo_activo, entrenador}
      true ->
        {:ok, entrenador}
    end
  end

  @impl true
  def handle_call({:listar_salas, pid_usuario}, _from, estado) do

    usuario = Map.get(estado.sesiones, pid_usuario)
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, {:error, "Usuario No Encontrado"}, estado}

      _entrenador ->
        salas_intercambio =
          if map_size(estado.intercambios) == 0 do
            "No hay salas de intercambio activas"
          else
            estado.intercambios
            |> Enum.with_index(1)
            |> Enum.map(fn {{id_sala, _pid_sala}, index} ->
              """
              #{index}. ID Sala: #{id_sala}
              """
            end)
            |> Enum.join("\n")
          end

          salas_batalla =
            if map_size(estado.batallas) == 0 do
              "No hay salas de batalla activas"
            else
              estado.batallas
              |> Enum.with_index(1)
              |> Enum.map(fn {{id_sala, _pid_sala}, index} ->
                """
                #{index}. ID Sala: #{id_sala}
                """
              end)
              |> Enum.join("\n")
            end

          mensaje =
            """
            ========= SALAS DE INTERCAMBIO =========
            #{salas_intercambio}
            ========= SALAS DE BATALLA =========
            #{salas_batalla}
            """
      {:reply, {:ok, mensaje}, estado}
    end
  end

  #*****MODIFICADA
  @impl true
  def handle_call({:unirse_sala_batalla, pid_usuario, pokemon_inicial, id_sala}, _from, estado) do
    usuario = Map.get(estado.sesiones, pid_usuario)
    #PID del proceso para Llamarlo
    sala = Map.get(estado.batallas, String.upcase(id_sala))
    entrenador = Map.get(estado.entrenadores, usuario)
    IO.inspect(estado.batallas)
    IO.inspect(id_sala)
    IO.inspect(sala)

    case sala do
      nil ->
        {:reply, {:error,"No Existe Sala de Batalla"}, estado}
      sala ->
        pid_sala = sala.pid_sala

        case preparar_equipo_batalla(pid_usuario, estado) do

          {:error, razon} -> {:reply, {:error, razon}, estado}

          {:sin_equipo_activo, _entrenador} -> {:reply, {:error, "No tienes equipo activo"}, estado}

          {:ok, entrenador} ->
            case GestionEquipos.armar_equipo_batalla(estado.pokemones, entrenador, pokemon_inicial) do
              {:error, razon} ->
                {:reply, {:error, razon}, estado}

              {:ok, equipo_batalla, pokemon_activo} ->
                case GenServer.call(pid_sala, {:unirse_sala_batalla, usuario, pid_usuario, equipo_batalla, pokemon_activo}) do
                  {:error,:participantes_completos} ->
                    {:reply, {:error,"La Sala Tiene los Participantes Completos"}, estado}
                  {:ok, mensaje} ->
                    sala_actualizada = %{ sala | usuarios: sala.usuarios ++ [pid_usuario]}
                    batallas_actualizadas =
                      Map.put(estado.batallas, String.upcase(id_sala), sala_actualizada)
                      nuevo_estado = %{estado | batallas: batallas_actualizadas}
                      {:reply, {:ok, mensaje, pid_sala}, nuevo_estado}
                end
            end
        end
    end
  end

  @impl true
  def handle_cast({:recompensa, pid_usuario, monedas}, estado) do

    usuario = Map.get(estado.sesiones, pid_usuario)

    case Map.get(estado.entrenadores, usuario) do

      nil -> {:noreply, estado}

      entrenador ->
        entrenador_actualizado = %{entrenador |
          monedas_actuales: entrenador.monedas_actuales + monedas,
          monedas_acumuladas: entrenador.monedas_acumuladas + monedas
        }

        entrenadores_actualizados =
          Map.put(estado.entrenadores, usuario, entrenador_actualizado)

        nuevo_estado = %{ estado | entrenadores: entrenadores_actualizados}

        Persistencia.escribir_entrenador(entrenadores_actualizados)

        send(pid_usuario, {:mensaje_batalla, "Has recibido #{monedas} monedas"})

        {:noreply, nuevo_estado}
    end
  end

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


      Enum.any?(estado.batallas, fn {_codigo, sala} ->
        sala.pid_sala == pid
      end) ->

        {id_sala, _sala} = Enum.find(estado.batallas, fn {_codigo, sala} ->
          sala.pid_sala == pid end)

        IO.puts("Se eliminó la sala de batallas #{id_sala}")

        batallas_actualizadas = Map.delete(estado.batallas, id_sala)

        nuevo_estado = %{ estado | batallas: batallas_actualizadas}

        {:noreply, nuevo_estado}

      true ->
        {:noreply, estado}
    end
  end
end
