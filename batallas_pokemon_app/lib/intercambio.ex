defmodule Intercambio do
  use GenServer

  def start_link({id_sala,creador,pid_creador}) do
    GenServer.start_link(__MODULE__, {id_sala,creador,pid_creador})
  end

  @impl true
  def init({id_sala,creador,pid_creador}) do

    Process.send_after(self(), {:timeout_sala, id_sala}, 60000)

    estado= %{
      id_sala: id_sala,
      pid_creador: pid_creador,
      creador: creador,
      invitado: nil,
      pokemon_creador: nil,
      pokemon_invitado: nil,
      confirmo_creador: false,
      confirmo_invitado: false
    }

    {:ok,estado}

  end

  @impl true

  def handle_info({:timeout_sala, id_sala}, estado) do
    if estado.invitado == nil do
      send(estado.pid_creador,{:sala_cancelada, id_sala})
      {:stop, :normal, estado}
    else
      {:noreply, estado}
    end
  end





  """
  @impl true
  def handle_cast({:join, pid, username}, state) do
    # Monitorear el proceso del usuario para detectar desconexiones
    Process.monitor(pid)
    IO.puts("{username} se unió a {state.name}")
    # Se agrega el usuario al estado de la sala, su pid es la clave y su nombre es el valor
    {:noreply, %{state | users: Map.put(state.users, pid, username)}}
  end

  @impl true
  def handle_cast({:leave, pid}, state) do
    # Eliminar al usuario dado su pid
    {username, users} = Map.pop(state.users, pid)
    IO.puts("{username} salió de {state.name}")
    {:noreply, %{state | users: users}}
  end

  @impl true
  def handle_cast({:message, from_pid, msg}, state) do
    # Obtener el nombre del usuario que envió el mensaje usando su pid
    username = Map.get(state.users, from_pid, "Desconocido")
    full = "{username}: {msg}"
    # Enviar el mensaje a todos los usuarios conectados a la sala
    Enum.each(state.users, fn {pid, _} -> send(pid, {:chat, state.name, full}) end)
    {:noreply, %{state | messages: [full | state.messages]}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _}, state) do
    # Eliminar al usuario desconectado cuando su proceso muere
    {username, users} = Map.pop(state.users, pid)
    IO.puts("{username} desconectado de {state.name}")
    {:noreply, %{state | users: users}}
  end
  """



end
