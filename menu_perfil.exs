defmodule MenuPerfil do
  @nodo_servidor :servidor@localhost

  def mostrar(pid) do
    loop(pid)
  end

  defp loop(pid) do
    Util.imprimir_mensaje("""

    -------- PERFIL --------
    1. Ver perfil
    2. Ver inventario
    3. Listar equipos
    4. Clasificación
    5. Volver
    ------------------------

    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)

    case opcion do
      1 ->
        ver_perfil(pid)
        loop(pid)
      2 ->
        ver_inventario(pid)
        loop(pid)
      3 ->
        listar_equipos(pid)
        loop(pid)
      4 ->
        generar_clasificacion(pid)
        loop(pid)
      5 ->
        :ok  #Regresa al menu usuario loop_principal
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
    end
  end

  def ver_perfil(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_perfil, pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")
      perfil ->
        Util.imprimir_mensaje(perfil)
    end
  end

  def ver_inventario(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_inventario,pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      inventario ->
        Util.imprimir_mensaje(inventario)
    end
  end

   def listar_equipos(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_equipos,pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      {:ok,equipos} ->
        Util.imprimir_mensaje(equipos)
    end
  end

  def generar_clasificacion(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:generar_clasificacion,pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      clasificacion ->
        Util.imprimir_mensaje(clasificacion)
    end
  end
end

#======================================MenuTienda=========================================

defmodule MenuTienda do
  @nodo_servidor :servidor@localhost

  def mostrar(pid) do
    loop(pid)
  end

  defp loop(pid) do
    Util.imprimir_mensaje("""

    ------ TIENDA ------
    1. Ver tienda
    2. Comprar sobre
    3. Ver sobres pendientes
    4. Abrir sobre
    5. Volver
    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)
    Util.imprimir_mensaje("\n")

    case opcion do
      1 ->
        ver_tienda(pid)
        loop(pid)
      2 ->
        comprar_sobre(pid)
        loop(pid)
      3 ->
        ver_sobres_pendientes(pid)
        loop(pid)
      4 ->
        abrir_sobre(pid)
        loop(pid)
      5 ->
        :ok
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
      end
  end

  def ver_tienda(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_tienda, pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      tienda ->
        Util.imprimir_mensaje(tienda)
    end
  end

  def comprar_sobre(pid) do
    mensaje = """
    Tipos de Sobres en Tienda:
    - 1. Basico
    - 2. Avanzado
    """
    Util.imprimir_mensaje(mensaje)
    tipo = Util.leer("Ingrese el Tipo de Sobre que Desea Comprar: ", :integer)
    Util.imprimir_mensaje("\n")

    case tipo do
      1 -> ejecutar_compra(pid, "basico")
      2 -> ejecutar_compra(pid, "avanzado")
      _ ->
        Util.imprimir_error("Opción inválida. Intente Nuevamente.")
        comprar_sobre(pid)
    end
  end

  defp ejecutar_compra(pid, tipo_sobre) do
    case GenServer.call({Servidor, @nodo_servidor}, {:comprar_sobre, pid, tipo_sobre}) do
      {:error, razon} ->
        Util.imprimir_error(razon)

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def ver_sobres_pendientes(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_sobres, pid}) do
      {:error, razon} ->
        Util.imprimir_error(razon)

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def abrir_sobre(pid) do
    id_sobre = Util.leer("Ingrese el Id del Sobre que Desea Abrir: ", :string)
    case GenServer.call({Servidor, @nodo_servidor}, {:abrir_sobre, pid, id_sobre}) do
      {:error, razon} ->
        Util.imprimir_error(razon)

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
    end
  end
end

#======================================MenuEquipos=========================================

defmodule MenuEquipos do
  @nodo_servidor :servidor@localhost

  def mostrar(pid) do
    loop(pid)
  end

  defp loop(pid) do
    Util.imprimir_mensaje("""

    -------- EQUIPOS ---------
    1. Crear Equipo
    2. Listar Equipos
    3. Quitar pokemon de equipo
    4. Agregar pokemon a equipo
    5. Usar Equipo
    6. Volver
    --------------------------

    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)

    case opcion do
      1 ->
        crear_equipo(pid)
        loop(pid)
      2 ->
        listar_equipos(pid)
        loop(pid)
      3 ->
        quitar_pokemon_equipo(pid)
        loop(pid)
      4 ->
        agregar_pokemon_equipo(pid)
        loop(pid)
      5 ->
        usar_equipo(pid)
        loop(pid)
      6 ->
        :ok  #Regresa al menu usuario loop_principal
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
    end
  end

  def crear_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :crear_equipo,
        Util.leer("Ingrese el nombre del equipo que desea crear: ", :string),
        Util.leer("Ingrese los ids de los pokemones a incluir separados por espacio (Máximo 3 pokemones válidos): ",:string),
        pid}) do

      nil ->
        Util.imprimir_error("No se pudo procesar solicitud")
      mensaje ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def listar_equipos(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :ver_equipos,
        pid}) do

      nil ->
        Util.imprimir_error("No se pudo procesar solicitud")
      {:ok,mensaje} ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def quitar_pokemon_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :quitar_pokemon_equipo,
        Util.leer("Ingrese el nombre del equipo al que desea quitar un pokemon: ", :string),
        Util.leer("Ingrese el id del pokemon que desea quitar: ",:string),
        pid}) do

      nil ->
        Util.imprimir_error("No se pudo procesar solicitud")
      mensaje ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def agregar_pokemon_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :agregar_pokemon_equipo,
        Util.leer("Ingrese el nombre del equipo al que desea agregar un pokemon: ", :string),
        Util.leer("Ingrese el id del pokemon que desea agregar: ",:string),
        pid}) do

      nil ->
        Util.imprimir_error("No se pudo procesar solicitud")
      mensaje ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def usar_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :usar_equipo,
        Util.leer("Ingrese el nombre del equipo que desea cargar para batalla: ", :string),
        pid}) do
      nil ->
        Util.imprimir_error("No se pudo procesar solicitud")
      mensaje ->
        Util.imprimir_mensaje(mensaje)
    end
  end
end

  #======================================MenuIntercambio=========================================

defmodule MenuIntercambio do
    @nodo_servidor :servidor@localhost

    def mostrar(pid) do
      loop(pid)
    end

    defp loop(pid) do
      Util.imprimir_mensaje("""

      -------- INTERCAMBIOS ---------
      1. Crear Sala de Intercambios
      2. Unirse a sala
      3. Volver
      --------------------------

      """)

      opcion = Util.leer("Ingrese una opción: ", :integer)

      case opcion do
        1 ->
          crear_sala_intercambio(pid)
          loop(pid)
        #2 ->
          #unirse_sala(pid)
          #loop(pid)
        3 ->
          :ok  #Regresa al menu usuario loop_principal
        _ ->
          Util.imprimir_error("Opción inválida. Intente nuevamente")
          loop(pid)
      end
    end

    def crear_sala_intercambio(pid) do
      case GenServer.call({Servidor, @nodo_servidor}, { :crear_sala_intercambio, pid}) do
        nil ->
          Util.imprimir_error("No se pudo procesar solicitud")
        mensaje ->
          Util.imprimir_mensaje(mensaje)
      end
      receive do
        {:sala_cancelada, codigo} ->
          Util.imprimir_error("La sala con #{codigo} fue cancelada por timeout")
        end
    end
end

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
    4. Volver
    ----------------------------------

    """)

    opcion = Util.leer("Ingrese una Opción: ", :integer)

    case opcion do
      1 ->
        listar_salas(pid)
        loop(pid)
      2 ->
        crear_sala_batalla(pid)
        loop(pid)
      3 ->
        unirse_sala_batalla(pid)
        loop(pid)
      4 ->
        :ok
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
    end
  end

  def crear_sala_batalla(pid) do
    equipo = Util.leer("Ingrese el Nombre del Equipo a Usar en Batalla: ", :string)
    case GenServer.call({Servidor, @nodo_servidor}, {:usar_equipo, equipo, pid}) do
      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        pokemon_inicial = Util.leer("Ingrese el id del Pokemon Inicial: ", :string)
        case GenServer.call({Servidor, @nodo_servidor}, {:crear_sala_batalla, pid, pokemon_inicial}) do
          {:ok, mensaje_sala, pid_sala} ->
            Util.imprimir_mensaje(mensaje_sala)
            loop_batallas(pid, pid_sala)

          {:error, razon} ->
            Util.imprimir_error(razon)
        end

      {:error, razon} ->
        Util.imprimir_error(razon)
    end
  end

  def listar_salas(pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:listar_salas, pid}) do
      {:error, mensaje } ->
        Util.imprimir_error(mensaje)

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
    end
  end

  def unirse_sala_batalla(pid) do
    sala_a_unirse = Util.leer("Ingrese el Código de la Sala de Batalla a la que se Desea Unir: ", :string)
    equipo = Util.leer("Ingrese el Nombre del Equipo a Usar en Batalla: ", :string)
    case GenServer.call({Servidor, @nodo_servidor}, {:usar_equipo, equipo, pid}) do
      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        pokemon_inicial = Util.leer("Ingrese el id del Pokemon Inicial: ", :string)
        case GenServer.call({Servidor, @nodo_servidor}, {:unirse_sala_batalla, pid, pokemon_inicial, sala_a_unirse}) do
          {:ok, mensaje_sala, pid_sala} ->
            Util.imprimir_mensaje(mensaje_sala)
            #Voy a Escuchar
            loop_batallas(pid, pid_sala)

          {:error, razon} ->
            Util.imprimir_error(razon)
        end

      {:error, razon} ->
        Util.imprimir_error(razon)
    end
  end

  def loop_batallas(pid_usuario, pid_sala) do
    receive do
      # Sala creada (solo creador)
      {:sala_creada, id} ->
        Util.imprimir_mensaje("Sala creada: #{id}")
        loop_batallas(pid_usuario, pid_sala)

      # Otro jugador se une
      {:unido_sala, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        loop_batallas(pid_usuario, pid_sala)

      # Inicio de batalla - Mensajes Persona
      {:batalla_iniciada} ->
        Util.imprimir_mensaje("¡La batalla ha comenzado!")
        loop_batalla_turnos(pid_usuario, pid_sala)

      # Cancelación
      {:sala_cancelada, id} ->
        Util.imprimir_error("Sala #{id} cancelada")
        loop(pid_usuario)
    end
  end

  defp loop_batalla_turnos(pid_usuario, pid_sala) do
    receive do
      # Mostrar turno
      {:turno, mensaje} ->
        Util.imprimir_mensaje(mensaje)

        accion =
          Util.leer("Acción (ataque nombre_movimiento | cambiar ID | rendirse): ", :string)

        GenServer.cast(pid_sala, {:accion, pid_usuario, accion})

        loop_batalla_turnos(pid_usuario, pid_sala)

      # Resultado de turno
      {:resultado_turno, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        loop_batalla_turnos(pid_usuario, pid_sala)

      # Ganador
      {:ganador, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        loop(pid_usuario)

      # Perdedor
      {:perdedor, mensaje} ->
        Util.imprimir_error(mensaje)
        loop(pid_usuario)

    end
  end
end
