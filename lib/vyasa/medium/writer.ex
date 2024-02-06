defmodule Vyasa.Medium.Writer do
  @behaviour Phoenix.LiveView.UploadWriter

  alias Vyasa.Medium.Store

  @impl true
  def init(struct) do
    {local_path, ext_path} = Store.path(struct)
    with {:ok, file} <- File.open(local_path, [:binary, :write]),
           %{bucket: bucket} = config <- Store.s3_config(),
           s3_op <- ExAws.S3.initiate_multipart_upload(bucket, file_name) do
      {:ok, %{file: file, path: local_path, key: ext_path, chunk: 1, s3_op: s3_op, s3_config: ExAws.Config.new(config)}}
    end
  end

  @impl true
  def meta(state) do
    %{local_path: state.path, key: state.key}
  end

  @impl true
  def write_chunk(data, state) do
    case IO.binwrite(state.file, data) do
      :ok ->
        part = ExAws.S3.Upload.upload_chunk!({data, state.chunk}, state.s3_op, state.s3_config)
        {:ok, %{state | chunk: state.chunk+1, parts: [part | state.parts]}}
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def close(state, _reason) do
    case {File.close(state.file), ExAws.S3.Upload.complete(state.parts, state.s3_op, state.s3_config)} do
      {:ok, {:ok, _}} ->
        {:ok, state}
      {{:error, reason}, _} -> {:error, reason}
      {_,{:error, reason}} -> {:error, reason}
    end
  end
end
