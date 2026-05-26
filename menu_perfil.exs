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
    5. Eliminar equipo
    6. Usar Equipo
    7. Volver
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
        eliminar_equipo(pid)
        loop(pid)
      6 ->
        usar_equipo(pid)
        loop(pid)
      7 ->
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

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error,mensaje} ->
        Util.imprimir_error(mensaje)
    end
  end

  def listar_equipos(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :ver_equipos,
        pid}) do

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error,mensaje} ->
        Util.imprimir_error(mensaje)
    end
  end

  def quitar_pokemon_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :quitar_pokemon_equipo,
        Util.leer("Ingrese el nombre del equipo al que desea quitar un pokemon: ", :string),
        Util.leer("Ingrese el id del pokemon que desea quitar: ",:string),
        pid}) do

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error,mensaje} ->
        Util.imprimir_error(mensaje)
    end
  end

  def agregar_pokemon_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :agregar_pokemon_equipo,
        Util.leer("Ingrese el nombre del equipo al que desea agregar un pokemon: ", :string),
        Util.leer("Ingrese el id del pokemon que desea agregar: ",:string),
        pid}) do

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error,mensaje} ->
        Util.imprimir_error(mensaje)
    end
  end

  def eliminar_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      { :eliminar_equipo,
        Util.leer("Ingrese el nombre del equipo que desea eliminar: ", :string),
        pid}) do

      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error,mensaje} ->
        Util.imprimir_error(mensaje)
    end
  end

  def usar_equipo(pid) do
    case GenServer.call(
      {Servidor, @nodo_servidor},
      {:usar_equipo,
        Util.leer("Ingrese el nombre del equipo que desea cargar para batalla: ", :string),
        pid}) do
      {:ok, mensaje} ->
        Util.imprimir_mensaje(mensaje)
      {:error, mensaje} ->
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

        2 ->
          unirse_sala_intercambio(pid)

        3 ->
          :ok  #Regresa al menu usuario loop_principal
        _ ->
          Util.imprimir_error("Opción inválida. Intente nuevamente")
          loop(pid)
      end
    end

    def crear_sala_intercambio(pid) do
      case GenServer.call(
        {Servidor, @nodo_servidor},
        { :crear_sala_intercambio,
          pid}) do

        {:error,mensaje} ->
          Util.imprimir_error(mensaje)
          loop(pid)
        {:ok,mensaje} ->
          Util.imprimir_mensaje(mensaje)
          loop_intercambios(pid)
      end
    end

    def unirse_sala_intercambio(pid) do
      case GenServer.call(
        {Servidor, @nodo_servidor},
        {:unirse_sala_intercambio,
        Util.leer("Ingrese el código de la sala de intercambio a la que se desea unir: ", :string),
        pid}) do

        {:error,mensaje} ->
          Util.imprimir_error(mensaje)
          loop(pid)
        {:ok,mensaje} ->
          Util.imprimir_mensaje(mensaje)
          loop_intercambios(pid)
        end

    end

    def loop_intercambios(pid) do

      receive do

        {:sala_creada, _id_sala} ->
          Util.imprimir_mensaje("Esperando conexión del otro usuario...")
          loop_intercambios(pid)

        {:sala_cancelada, codigo} ->
          Util.imprimir_mensaje("La sala con codigo #{codigo} fue cancelada")
          loop(pid)

        {:unido_sala, mensaje} ->
          Util.imprimir_mensaje(mensaje)
          loop_intercambios(pid)

        {:intercambio_completado, mensaje} ->
          Util.imprimir_mensaje(mensaje)
          loop(pid)

        {:ofrecimiento,mensaje} ->
          Util.imprimir_mensaje(mensaje)
          loop_intercambios(pid)

        {:opciones,mensaje,id_sala} ->
          case manejar_opciones(mensaje,id_sala,pid) do
            :continuar ->
              loop_intercambios(pid)
            :volver_menu ->
              loop(pid)
          end
      end
    end

    def procesar_mensajes_pendientes(pid) do
      receive do

        {:intercambio_completado, mensaje} ->
          Util.imprimir_mensaje(mensaje)
          procesar_mensajes_pendientes(pid)

        {:sala_cancelada, codigo} ->
          Util.imprimir_mensaje("La sala con codigo #{codigo} fue cancelada")
          procesar_mensajes_pendientes(pid)

        {:ofrecimiento, mensaje} ->
          Util.imprimir_mensaje(mensaje)
          procesar_mensajes_pendientes(pid)

        {:unido_sala, mensaje} ->
          Util.imprimir_mensaje(mensaje)
          procesar_mensajes_pendientes(pid)

      after
        10 ->
          :ok
      end
    end

    def  manejar_opciones(mensaje,id_sala,pid) do

      procesar_mensajes_pendientes(pid)

      entrada =
        Util.leer(mensaje, :string)
        |> String.downcase()
        |> String.split(" ", trim: true)

      case entrada do
        [] ->
          Util.imprimir_error("Ingrese una opción válida")
          manejar_opciones(mensaje,id_sala,pid)
        [opcion|resto] ->
          accion =
            case opcion do
              "ofrecer_pokemon" -> :ofrecer_pokemon
              "confirmar_intercambio" -> :confirmar_intercambio
              "cancelar_intercambio" -> :cancelar_intercambio
              _ -> :error
            end

          id_pokemon = List.first(resto)

          case GenServer.call({Servidor, @nodo_servidor},
          {:accion_intercambio,accion,id_pokemon,mensaje,id_sala,pid}) do

            {:error,:valor_incorrecto} ->
              Util.imprimir_error("No ingreso ninguna opción válida, intente nuevamente: ")
              :continuar

            {:error,mensaje} ->
              Util.imprimir_error(mensaje)
              :continuar

            {:ok,:cancelado} ->
              Util.imprimir_mensaje("Se canceló el intercambio")
              :volver_menu

            {:ok,mensaje} ->
              Util.imprimir_mensaje(mensaje)
              :continuar
            end
        end
      end
  end



 #======================================MenuBatalla=========================================

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

  #*****MODIFICADA
  def crear_sala_batalla(pid) do

    pokemon_inicial = Util.leer("Ingrese el id del Pokemon Inicial: ", :string)

    case GenServer.call( {Servidor, @nodo_servidor}, {:crear_sala_batalla, pid, pokemon_inicial}) do

      {:ok, mensaje_sala, pid_sala} ->
        Util.imprimir_mensaje(mensaje_sala)
        loop_batallas(pid, pid_sala)

      {:error, "No tienes equipo activo"} ->
        equipo = Util.leer("Ingrese el Nombre del Equipo a Usar en Batalla: ", :string)

        case GenServer.call({Servidor, @nodo_servidor}, {:usar_equipo, equipo, pid}) do

          {:ok, mensaje} ->
            Util.imprimir_mensaje(mensaje)

            case GenServer.call({Servidor, @nodo_servidor},{:crear_sala_batalla, pid, pokemon_inicial}) do

              {:ok, mensaje_sala, pid_sala} ->
                Util.imprimir_mensaje(mensaje_sala)
                loop_batallas(pid, pid_sala)

              {:error, razon} ->
                Util.imprimir_error(razon)
            end

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

  #*****MODIFICADA
  def unirse_sala_batalla(pid) do

    sala_a_unirse = Util.leer("Ingrese el Código de la Sala de Batalla a la que se Desea Unir: ", :string)
    pokemon_inicial = Util.leer("Ingrese el Id del Pokemon Inicial: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:unirse_sala_batalla, pid, pokemon_inicial, sala_a_unirse}) do

      {:ok, mensaje_sala, pid_sala} ->
        Util.imprimir_mensaje(mensaje_sala)
        loop_batallas(pid, pid_sala)

      {:error, "No tienes equipo activo"} ->
        equipo = Util.leer("Ingrese el Nombre del Equipo a Usar en Batalla: ", :string)

        case GenServer.call({Servidor, @nodo_servidor}, {:usar_equipo, equipo, pid}) do

          {:ok, mensaje} ->
            Util.imprimir_mensaje(mensaje)

            case GenServer.call({Servidor, @nodo_servidor}, {:unirse_sala_batalla, pid, pokemon_inicial, sala_a_unirse}) do

              {:ok, mensaje_sala, pid_sala} ->
                Util.imprimir_mensaje(mensaje_sala)
                loop_batallas(pid, pid_sala)

              {:error, razon} ->
                Util.imprimir_error(razon)
            end

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

      {:turno, turno, mensaje} ->

        Util.imprimir_mensaje(mensaje)
        padre = self()

        # Proceso separado SOLO para leer input
        spawn(fn ->
          accion = Util.leer("Acción (ataque nombre_movimiento | cambiar ID | rendirse): ",:string)

          #Enviamos acción al proceso principal
          send(padre, {:accion_usuario, turno, accion})
        end)

        #Igual Quedo Escuchando
        esperar_accion(pid_usuario, pid_sala, turno)

    {:resultado_turno, mensaje} ->
      Util.imprimir_mensaje(mensaje)
      loop_batalla_turnos(pid_usuario, pid_sala)

    {:ganador, mensaje} ->
      Util.imprimir_mensaje(mensaje)
      loop(pid_usuario)

    {:perdedor, mensaje} ->
      Util.imprimir_error(mensaje)
      loop(pid_usuario)
  end
end

  defp esperar_accion(pid_usuario, pid_sala, turno_actual) do

    receive do

      {:accion_usuario, turno_msg, accion} ->

        # Solo acepto acción si pertenece al turno actual
        if turno_msg == turno_actual do

          GenServer.cast(pid_sala, {:accion, pid_usuario, accion})

        end

        loop_batalla_turnos(pid_usuario, pid_sala)

      {:resultado_turno, mensaje} ->

        Util.imprimir_mensaje(mensaje)
        loop_batalla_turnos(pid_usuario, pid_sala)


      {:turno, nuevo_turno, mensaje} ->

        Util.imprimir_mensaje(mensaje)

        padre = self()

        spawn(fn -> accion =
            Util.leer( "Acción (ataque nombre_movimiento | cambiar ID | rendirse): ", :string)
          send(padre, {:accion_usuario, nuevo_turno, accion})
        end)

        esperar_accion(pid_usuario, pid_sala, nuevo_turno)

      {:ganador, mensaje} ->
        Util.imprimir_mensaje(mensaje)
        loop(pid_usuario)

      {:perdedor, mensaje} ->
        Util.imprimir_error(mensaje)
        loop(pid_usuario)
    end
  end
end
