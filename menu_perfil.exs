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
