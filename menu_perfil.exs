defmodule MenuPerfil do
  @nodo_servidor :servidor@localhost

  def mostrar(usuario, pid) do
    loop(usuario, pid)
  end

  defp loop(usuario, pid) do
    Util.imprimir_mensaje("""

    -------- PERFIL --------
    1. Ver perfil
    2. Ver inventario
    3. Listar equipos
    4. Clasificación
    5. Volver

    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)

    case opcion do
      1 ->
        ver_perfil(usuario, pid)
        loop(usuario, pid)
      2 ->
        ver_inventario(usuario, pid)
        loop(usuario, pid)
      #3 ->#Gestion.equipos
      #  listar_equipos(usuario, pid)
      #  loop(usuario, pid)
      4 ->
        generar_clasificacion(usuario, pid)
        loop(usuario, pid)
      5 ->
        :ok  #Salida del Menú
      _ ->
        Util.imprimir_error("Opción inválida. Intente nuevamente")
        loop(usuario, pid)
    end
  end

  def ver_perfil(usuario, pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_perfil, usuario, pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")
      perfil ->
        Util.imprimir_mensaje(perfil)
    end
  end

  def ver_inventario(usuario, pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:ver_inventario, usuario, pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      inventario ->
        Util.imprimir_mensaje(inventario)
    end
  end

  def generar_clasificacion(usuario, pid) do
    case GenServer.call({Servidor, @nodo_servidor}, {:generar_clasificacion, usuario, pid}) do
      nil ->
        Util.imprimir_error("Usuario No Encontrado")

      clasificacion ->
        Util.imprimir_mensaje(clasificacion)
    end
  end




end

defmodule MenuTienda do

  def mostrar(usuario) do
    loop(usuario)
  end

  defp loop(usuario) do
    Util.imprimir_mensaje("""

    ------ TIENDA ------
    1. Ver tienda
    2. Comprar sobre
    3. Abrir sobre
    4. Volver
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
        loop(usuario)
      end
  end
end
