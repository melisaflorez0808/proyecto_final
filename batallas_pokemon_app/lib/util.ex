defmodule Util do

  def leer(mensaje, :string) do
    IO.gets(mensaje)
    |> String.downcase()
    |> String.trim()
  end

  def leer(mensaje, :integer) do
    leer_con_parse(mensaje, fn(valor) -> Integer.parse(valor) end)
  end

  def leer(mensaje, :float) do
    leer_con_parse(mensaje, fn(valor) -> Float.parse(valor) end)
  end

  def leer_con_parse(mensaje, funcion) do
    valor = IO.gets(mensaje)
    |> String.trim()
    |> funcion.() #El punto es para ejecutar la función anonima

    case valor do
      {numero, _} -> numero
      :error ->
        "Valor Inválido. Intente Nuevamente"
        |> imprimir_error()
        leer_con_parse(mensaje, funcion)
    end
  end

  def imprimir_mensaje(mensaje), do: IO.puts(mensaje)
  def imprimir_error(mensaje), do: IO.puts(:standard_error, mensaje)

end
