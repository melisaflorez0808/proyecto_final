defmodule MenuBatalla do

  @nodo_servidor :servidor@localhost

  def mostrar(pid) do
    loop(pid)
  end

  defp loop(pid) do
    Util.imprimir_mensaje("""

    -------- SALAS DE BATALLA --------
    1. Listar salas
    2. Crear sala
    3. Unirse a sala
    4. Cargar equipo en sala
    5. Iniciar batalla
    6. Volver
    ----------------------------------

    """)

    opcion = Util.leer("Ingrese una Opción: ", :integer)

    case opcion do
      1 ->
        listar_salas(pid)
        loop(pid)
      2 ->
        crear_sala(pid)
        loop(pid)
      3 ->
        unirse_sala(pid)
        loop(pid)
      4 ->
        cargar_equipo(pid)
        loop(pid)
      5 ->
        iniciar_batalla(pid)
        loop(pid)
      6 ->
        :ok
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
    end
  end

  #---------Revisado
  def listar_salas(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:listar_salas, pid}) do
      {:ok, []} ->
        Util.imprimir_mensaje("No hay salas activas.")

      {:ok, salas} ->
        lineas =
          Enum.map(salas, fn {id, estado, jugadores, tiempo} ->
            texto_jugadores =
              if jugadores == "" do
                "-"
              else
                jugadores
              end

            "#{id} | #{estado} | Jugadores: #{texto_jugadores} | Turno: #{tiempo}s"
          end)

        Util.imprimir_mensaje(Enum.join(lineas, "\n"))
    end
  end

  #---------Revisado
  def crear_sala(pid) do
    tiempo = Util.leer("Tiempo Por Turno en Segundos (default 20): ", :integer)

    case GenServer.call({Servidor, @nodo_servidor}, {:crear_sala_batalla, tiempo, pid}) do
      {:ok, id} ->
        Util.imprimir_mensaje("Sala creada: #{id}")
        Util.imprimir_mensaje("Ya estás dentro. Usa ese ID en las opciones 4 y 5.")

      {:error, razon} ->
        Util.imprimir_error("#{inspect(razon)}")
    end
  end

  #---------------Revisado
  def unirse_sala(pid) do
    id_sala = Util.leer("Ingrese el ID de Sala a Unirse: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:unirse_sala_batalla, id_sala, pid}) do
      {:ok, :unido} ->
        Util.imprimir_mensaje("Te uniste a la sala #{id_sala}")

      {:error, razon} ->
        Util.imprimir_error("#{inspect(razon)}")
    end
  end

  #---------------Cargar Equipo
  def cargar_equipo(pid) do

    id_sala = Util.leer("ID de la Sala: ", :string)
    nombre = Util.leer("Nombre del Equipo Guardado: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:usar_equipo, nombre, pid}) do
      {:ok, _} ->
        case GenServer.call({Servidor, @nodo_servidor}, {:cargar_equipo_batalla, id_sala, pid}) do
          :ok ->
            Util.imprimir_mensaje("Equipo registrado en la sala #{id_sala}")

          {:error, razon} ->
            Util.imprimir_error("#{inspect(razon)}")
        end

      {:error, razon} ->
        Util.imprimir_error("#{inspect(razon)}")
    end
  end

  def iniciar_batalla(pid) do
    id_sala = Util.leer("ID de la sala: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:iniciar_batalla, id_sala, pid}) do
      {:ok, _pid_batalla, nodo} ->
        Util.imprimir_mensaje("Batalla iniciada en nodo #{nodo}. Esperando turnos...")
        recibir_batalla(pid, id_sala)

      {:error, razon} ->
        Util.imprimir_error("#{inspect(razon)}")
    end
  end

  defp recibir_batalla(pid, id_sala) do
    receive do
      {:nuevo_turno, ^id_sala, vista} ->
        Util.imprimir_mensaje(vista)
        accion = Util.leer("Acción > ", :string)
        GenServer.call({Servidor, @nodo_servidor}, {:batalla_accion, id_sala, accion, pid})
        recibir_batalla(pid, id_sala)

      {:batalla_log, ^id_sala, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        recibir_batalla(pid, id_sala)

      {:batalla_terminada, ganador, perdedor, resumen} ->
        Util.imprimir_mensaje("#{resumen}\nGanador: #{ganador} | Perdedor: #{perdedor}")
    end
  end
end
