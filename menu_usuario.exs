
defmodule Usuario do
  @nodo_servidor :servidor@localhost

  def main do
    IO.puts("Iniciando el nodo usuario....")
    {:ok, _} = Node.start(:cliente@localhost, :shortnames)
    Node.set_cookie(:ejemplo)
    IO.puts("El nodo usuario se ha iniciado!")

    #Intenta conectarse al nodo servidor
    case Node.connect(@nodo_servidor) do
      true ->
        enviar_mensajes()
      false ->
        IO.puts("No se puede establecer la conexión con el servidor")
    end
  end

  def enviar_mensajes() do

    # Envía un mensaje al nodo servidor y no espera una respuesta. Se debe usar el nombre del módulo (Carrito) y el nombre del nodo (@nodo_servidor)
  mensaje=
    GenServer.call(
      {Servidor, @nodo_servidor},
      { :agregar_usuario, {"santiago","456"}}
    )

    IO.puts(mensaje)

  end
end

Usuario.main()
