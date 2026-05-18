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

  def mostrar(pid) do
    loop(pid)
  end

  defp loop(pid) do
    Util.imprimir_mensaje("""

    ------ TIENDA ------
    1. Ver tienda
    2. Comprar sobre
    3. Abrir sobre
    4. Volver
    --------------------
    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)

    case opcion do
      #1 ->
      #  GestionTienda.ver_tienda()
      #  loop(usuario)
      #2 ->
      #  GestionTienda.comprar_sobre(usuario)
      #  loop(usuario)
      #3 ->
      #  GestionTienda.abrir_sobre(usuario)
      #  loop(usuario)
      #4 ->
      #  :ok
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(pid)
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
        :ok #provisional
        #usar_equipo(pid)
        #loop(pid)
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

end
