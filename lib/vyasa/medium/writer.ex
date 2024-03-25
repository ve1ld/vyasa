defmodule Vyasa.Medium.Writer do
  @behaviour Phoenix.LiveView.UploadWriter

  alias Vyasa.Medium.Store

  @impl true
  def init(struct) do
    {local_path, ext_path} = Store.path(struct)
    with {:ok, file} <- File.open(local_path, [:binary, :write]),
           %{bucket: bucket} = config <- Store.s3_config(),
           s3_op <- ExAws.S3.initiate_multipart_upload(bucket, ext_path) do
      {:ok, %{file: file, path: local_path, key: ext_path, chunk: 1, s3_op: s3_op, s3_config: ExAws.Config.new(:s3, config)}}
    end
  end

  def run(struct) do
    {local_path, ext_path} = Store.path(struct)
    with fs <- ExAws.S3.Upload.stream_file(local_path),
         %{bucket: bucket} = cfg <- Store.s3_config(),
           req <- ExAws.S3.upload(fs, bucket, ext_path),
         {:ok, %{status_code: 200, body: body}}  <- ExAws.request(req, config: cfg) do
      {:ok, body}
    else
      {:err, err} -> {:err, err}
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
