defmodule Servidor do

  use GenServer

  def main do

    IO.puts("Servidor iniciando....")
    {:ok, _} = Node.start(:servidor@localhost, :shortnames)
    Node.set_cookie(:ejemplo)
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
