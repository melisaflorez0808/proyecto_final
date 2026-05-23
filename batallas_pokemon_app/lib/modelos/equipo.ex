defmodule Equipo do

  @moduledoc """
  Modulo de struct equipo necesario para el CRUD del equipo
  """

  defstruct [
    pokemones: []
  ]

  def nuevo(pokemones) when length(pokemones) <1 do
    {:error,:debe_incluir_minimo_un_pokemon}
  end

  def nuevo(pokemones) when length(pokemones) >3 do
    {:error,:pokemones_exceden_maximo_permitido}
  end

  def nuevo(pokemones) do
    {:ok, %__MODULE__{pokemones: pokemones}}
  end

  def agregar_pokemon(equipo, _id_pokemon) when length(equipo.pokemones) >= 3 do
    {:error, :equipo_con_cupo_maximo}
  end

  def agregar_pokemon(equipo, id_pokemon) do
    if tiene_pokemon?(equipo,id_pokemon) do
      {:error, :pokemon_pertenece_al_equipo}
    else
      {:ok, %{equipo | pokemones: [id_pokemon|equipo.pokemones]}}
    end
  end

  def quitar_pokemon(equipo, id_pokemon) do
    if tiene_pokemon?(equipo,id_pokemon) do
      {:ok,%{equipo | pokemones: List.delete(equipo.pokemones,id_pokemon)}}
    else
      {:error,:no_existe_pokemon_equipo}
    end
  end

  def tiene_pokemon?(equipo, id) do
      Enum.any?(equipo.pokemones, fn id_pokemon ->
      id==id_pokemon
      end)
  end
end
