defmodule RadioThermostat.Client do
  use HTTPoison.Base

  def do_get(path, url, parameters \\ %{}) do
    case RadioThermostat.Client.get(url <> path, [], params: parameters, timeout: 5000, recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> Poison.Parser.parse!}
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} when status_code > 400 ->
        {:error, body}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def do_post(path, url, body) do
    {:ok, body} = Poison.encode(body)
    case RadioThermostat.Client.post(url <> path, body, timeout: 5000, recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case body |> Poison.Parser.parse! do
          %{"success" => 0} = payload -> {:ok, payload}
          payload -> {:error, payload}
        end
      {:ok, %HTTPoison.Response{body: body, status_code: status_code}} when status_code > 400 ->
        {:error, body}
      {:error, reason} ->
        {:error, reason}
    end
  end
end
