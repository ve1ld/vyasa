defmodule Vyasa.Medium.Ext.Stream do
  def stream([{_url, _path} | _] = data) do
    Task.async_stream(
      data,
      fn {url, path} ->
        download(url, path)
      end,
      timeout: :infinity
    )
  end

  def download(url, file_path) do
    IO.puts("Starting to process #{inspect(file_path)}...........")

    # Open a file to which binary chunks will be appended to.
    # this process is reset in case of redirection
    file_pid = File.open!(file_path, [:write, :binary])

    unless is_pid(file_pid), do: raise("File creation problem on disk")

    # the HTTP stream request
    Finch.build(:get, url)
    |> Finch.stream_while(Vyasa.Finch, nil, fn
      # we put the status in the "acc" to handle redirections
      {:status, status}, _acc ->
        {:cont, status}

      # - when we receive 302, we put the "location" header in the "acc"
      # - when we receive a 200, we put the "content-length" and the file name in the "acc",
      {:headers, headers}, acc ->
        handle_headers(headers, acc)

      # when we receive the "location" tuple, we recurse
      # otherwise, we write the chunk into the file and print out the current progress.
      {:data, data}, acc ->
        handle_data(data, acc, file_path, file_pid)
    end)

    case File.close(file_pid) do
      :ok ->
        {:halt, {file_path, :done}}

      {:error, _reason} ->
        {:halt, :error}
    end
  end

  def handle_headers(headers, status) when status in [301, 302, 303, 307, 308] do
    IO.puts("REDIR: #{status}")

    {:cont, Enum.find(headers, &(elem(&1, 0) == "location"))}
  end

  def handle_headers(headers, 200) do
    {"content-length", size} =
      Enum.find(headers, &(elem(&1, 0) == "content-length"))

    case size do
      nil ->
        {:cont, {0, 0}}

      size ->
        {:cont, {0, String.to_integer(size)}}
    end
  end

  def handle_headers(_, status) do
    dbg(status)
    {:halt, :bad_status}
  end

  def handle_data(_data, {"location", location}, file_path, file_pid) do
    if Process.alive?(file_pid), do: :ok = File.close(file_pid)

    # recursion
    download(location, file_path)
  end

  def handle_data(data, {processed, size}, file_path, file_pid) do
    case IO.binwrite(file_pid, data) do
      :ok ->
        processed =
          if is_integer(size) and size > 0 do
            (processed + byte_size(data))
            |> tap(fn processed ->
              IO.inspect(Float.round(processed * 100 / size, 1),
                label: "Processed #{inspect(file_path)} %: "
              )
            end)
          else
            processed + byte_size(data)
          end

        {:cont, {processed, size}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
