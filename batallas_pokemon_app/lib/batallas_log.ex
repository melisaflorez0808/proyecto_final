defmodule LoggerBatallas do

  @archivo "battles.log"

  def guardar_batalla(pid_sala, creador, ganador) do

    fecha =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.to_string()

    linea =
      "#{fecha} | Sala=#{inspect(pid_sala)} | Creador=#{creador} | Ganador=#{ganador}\n"

    File.write(@archivo, linea, [:append])
  end
end
