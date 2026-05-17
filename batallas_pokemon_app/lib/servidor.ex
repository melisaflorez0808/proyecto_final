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

    estado = %{
      pokemones: Persistencia.leer_pokemones(),
      movimientos: Persistencia.leer_movimientos(),
      entrenadores: Persistencia.leer_entrenadores(),
      tienda: Persistencia.leer_tienda(),
      sesiones: %{}
    }

    IO.puts("Servidor iniciado correctamente")
    IO.inspect(estado.entrenadores)
    IO.inspect(estado.pokemones)
    IO.inspect(estado.tienda)
    IO.inspect(estado.movimientos)

    {:ok, estado}
  end

  #Login
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
          {:reply, {:ok, existente}, estado}
        else
          {:reply, {:error, :clave_incorrecta}, estado}
        end
    end
  end

  #-------------------- Perfil ---------------------------------------
  def handle_call({:ver_perfil, usuario, _pid}, _from, estado) do
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionPerfil.ver_perfil(usuario, entrenador)
        {:reply, respuesta, estado}
    end
  end

  def handle_call({:ver_inventario, usuario, pid}, _from, estado) do
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionPerfil.ver_inventario(usuario, entrenador, estado)
        {:reply, respuesta, estado}
    end
  end

  def handle_call({:generar_clasificacion, usuario, pid}, _from, estado) do
    case Map.get(estado.entrenadores, usuario) do
      nil ->
        {:reply, nil, estado}

      entrenador ->
        respuesta = GestionPerfil.generar_clasificacion(estado.entrenadores)
        {:reply, respuesta, estado}
    end
  end


  ##SOLO POR PROBAR

  @impl true
  def handle_call({:agregar_usuario,{nombre,clave}}, _from, estado) do
    IO.puts("Usuario agregado #{nombre}")

    entrenadores_actualizados=
      Map.put(estado.entrenadores, nombre, %Entrenador{clave: clave})

    nuevo_estado =
      Map.put(
        estado,
        :entrenadores,
        entrenadores_actualizados
      )
      Persistencia.escribir_entrenador(entrenadores_actualizados)

    {:reply, "Usuario agregado", nuevo_estado}
  end

end
