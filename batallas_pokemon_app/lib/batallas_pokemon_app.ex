defmodule BatallasPokemonApp do
  use Application

  def start(_type,_args) do
    Servidor.main()
    {:ok,self()}
  end
end
