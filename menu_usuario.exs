defmodule Usuario do

  Code.require_file("util.exs", _DIR_)
  Code.require_file("menu_perfil.exs", _DIR_)

  @nodo_servidor :servidor@localhost

  def main do
    IO.puts("Iniciando el nodo usuario....")
    {:ok, _} = Node.start(:usuario@localhost, :shortnames)
    Node.set_cookie(:pokemon)
    IO.puts("El nodo usuario se ha iniciado!")

    #Intenta conectarse al nodo servidor
    case Node.connect(@nodo_servidor) do
      true ->
        iniciar()
      false ->
        IO.puts("No se puede establecer la conexión con el servidor")
    end
  end

  def iniciar do
    pid = login()
    loop_principal(pid)
    logout(pid)
  end

  defp login do
    Util.imprimir_mensaje("Ingrese sus datos para acceder al sistema: ")
    usuario = Util.leer("Usuario: ", :string)
    clave = Util.leer("Clave: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:login, usuario, clave, self()}) do
      {:ok, :existente} ->
        #Retorno el pid del usuario, que esta guardado en sesiones del estado del servidor
        Util.imprimir_mensaje("Ingreso Correcto de Usuario #{usuario}")
        self()

      {:ok, _nuevo} ->
        #Retorno el pid del usuario, que esta guardado en sesiones del estado del servidor
        Util.imprimir_mensaje("Se registró el Usuario #{usuario} ¡¡Recibe como premio Sobre de Regalo!!")
        self()

      {:error, :clave_incorrecta} ->
        Util.imprimir_error("Clave incorrecta")
        login()
    end
  end

  defp logout(pid) do

    case GenServer.call({Servidor, @nodo_servidor}, {:logout, pid}) do
      {:error, :usuario_no_logueado} ->
        Util.imprimir_mensaje("El usuario nunca estuvo logueado")

      {:ok,:finalizado} ->
        Util.imprimir_mensaje("Sesión finalizada correctamente...")
        self()
    end

  end

  defp loop_principal(pid) do
    Util.imprimir_mensaje("""

    ------------- MENÚ PRINCIPAL -------------
    1. Perfil, Inventario y Clasificación
    2. Tienda y Sobres
    3. Intercambio Pokémon
    4. Equipos Pokémon
    5. Salas de batalla
    6. Salir
    ------------------------------------------

    """)

    opcion = Util.leer("Ingrese una opción: ", :integer)

    case opcion do
      1 ->
        MenuPerfil.mostrar(pid)
        loop_principal(pid)
      2 ->
        MenuTienda.mostrar(pid)
        loop_principal(pid)
      3 ->
        MenuIntercambio.mostrar(pid)
        loop_principal(pid)
      4 ->
        MenuEquipos.mostrar(pid)
        loop_principal(pid)
      #5 ->
      #  MenuSalasBatalla.mostrar(pid)
      #  loop_principal(pid)
      6 ->
        Util.imprimir_mensaje("Saliendo......")
      _ ->
        Util.imprimir_error("Opción inválida. Intente Nuevamente")
        loop_principal(pid)
    end
  end
end
Usuario.main()
