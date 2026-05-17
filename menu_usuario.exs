defmodule Usuario do

  Code.require_file("util.exs", __DIR__)
  Code.require_file("menu_perfil.exs", __DIR__)

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
    usuario = login()
    loop_principal(usuario)
  end

  defp login do
    usuario = Util.leer("Usuario: ", :string)
    clave = Util.leer("Clave: ", :string)

    case GenServer.call({Servidor, @nodo_servidor}, {:login, usuario, clave, self()}) do
      {:ok, _user} ->
        #Retorno al usuario para seguir trabajando con él
        Util.imprimir_mensaje("Ingreso Correcto de Usuario")
        usuario

      {:error, :clave_incorrecta} ->
        Util.imprimir_error("Clave incorrecta")
        login()
    end
  end

  defp loop_principal(usuario) do
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
        MenuPerfil.mostrar(usuario, self())
        loop_principal(usuario)
      #2 ->
      #  MenuTienda.mostrar(usuario)
      #  loop_principal(usuario)
      #3 ->
      # MenuIntercambio.mostrar(usuario)
      #  loop_principal(usuario)
      #4 ->
      #  MenuEquipos.mostrar(usuario)
      #  loop_principal(usuario)
      #5 ->
      #  MenuSalasBatalla.mostrar(usuario)
      #  loop_principal(usuario)
      6 ->
        Util.imprimir_mensaje("Saliendo......")
      _ ->
        Util.imprimir_error("Opción inválida. Intente Nuevamente")
        loop_principal(usuario)
    end
  end
end
Usuario.main()
