defmodule Equipo do

  @moduledoc """
  Modulo de struct equipo necesario para el CRUD del equipo
  """

  defstruct [
    pokemones: []
  ]

  def nuevo(pokemones) when pokemones.length <1 do
    {:error,:debe_incluir_minimo_un_pokemon}
  end

  def nuevo(pokemones) when pokemones.length >3 do
    {:error,:pokemones_exceden_maximo_permitido}
  end

  def nuevo(pokemones) do
    {:ok, %__MODULE__{pokemones: pokemones}}
  end

  def agregar_pokemon(pokemones, pokemon) do
    if tiene_pokemon?(pokemones,pokemon) do
      {:error, :pokemon_pertenece_al_equipo}
    else
      {:ok, %{pokemones | pokemones: [pokemon|pokemones]}}
    end
  end

  def quitar_pokemon(pokemones, pokemon) do
    if tiene_pokemon?(pokemones,pokemon) do
      {:ok,%{pokemones | pokemones: List.delete(pokemones,pokemon)}}
    else
      {:error,:no_existe_pokemon_en_el_equipo}
    end
  end

  def tiene_pokemon?(pokemones, pokemon) do
      Enum.any?(pokemones, fn pokemon_equipo ->
      pokemon.id==pokemon_equipo.id
      end)
  end
end
