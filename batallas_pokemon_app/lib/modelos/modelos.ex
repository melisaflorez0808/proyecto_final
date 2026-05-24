defmodule EspeciePokemon do
  defstruct [
    tipos: [],
    ataque_base: 0,
    defensa_base: 0,
    velocidad_base: 0
  ]
end

defmodule Movimiento do
    defstruct [
      :nombre,
      :tipo,
      :poder_base
  ]
end

defmodule Sobre do
    defstruct [
      :precio,
      :probabilidades
    ]
end

defmodule PokemonInstancia do
    @enforce_keys [:especie, :dueno_original, :rareza, :ataque, :defensa, :velocidad, :movimientos]
    defstruct [
      :especie,
      :dueno_original,
      :rareza,
      :ataque,
      :defensa,
      :velocidad,
      :movimientos
    ]
end

defmodule Entrenador do
    defstruct [
      :clave,
      :victorias,
      :monedas_actuales,
      :monedas_acumuladas,
      :equipo_activo,
      inventario: %{},
      sobres_pendientes: %{},
      equipos: %{}
    ]
end

defmodule SobrePendiente do
    defstruct [
      :tipo
    ]
end
