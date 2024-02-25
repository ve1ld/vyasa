defmodule Vyasa.Medium.Store do
  @moduledoc """
  S3 Object Storage Service Communicator  using HTTP POST sigv4
  https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
  """

  alias Vyasa.Medium

  @bucket "vyasa"

  def path(st) when is_struct(st) do
    #input and output paths
    {local_path(st), path_constructor(st)}
  end

  def get(st) when is_struct(st) do
    signer(:get, path_constructor(st))
  end

  def get(path) do
    signer(:get, path)
  end

  def get!(st) when is_struct(st) do
    signer!(:get, path_constructor(st))
  end

  def get!(path) do
    signer!(:get, path)
  end

  def put(struct) do
    signer(:put, path_constructor(struct))
  end

  def put!(struct) do
    signer!(:put, path_constructor(struct))
  end

  def hydrate(%Medium.Voice{} = voice) do
    %{voice | file_path: get!(voice)}
  end

  def hydrate(rt), do: rt


  def s3_config do
    %{
      region: System.fetch_env!("AWS_DEFAULT_REGION"),
      bucket: @bucket,
      access_key_id: System.fetch_env!("AWS_ACCESS_KEY_ID"),
      secret_access_key: System.fetch_env!("AWS_SECRET_ACCESS_KEY")
    }
  end

  defp signer!(action, path) do
    {:ok, url} = signer(action, path)
    url
  end

  defp signer(:headandget, path) do
    ExAws.S3.head_object("orbistertius", path)
    |> ExAws.request!()
    ## with 200
    signer(:get, path)
    ## else (pass signer link of fallback image function or nil)
  end


  defp signer(action, path) do
    ExAws.Config.new(:s3, s3_config()) |>
      ExAws.S3.presigned_url(action, @bucket, path,
        [expires_in: 88888, virtual_host: false, query_params: [{"ContentType", "application/octet-stream"}]])
  end

  defp local_path(%Medium.Voice{file_path: local_path}) do
    local_path
  end

  defp path_constructor(%Medium.Voice{__meta__: %{source: type}, id: id}) do
    "#{type}/#{id}.mp3" #default to mp3 ext for now
  end

  defp path_constructor(%Medium.Voice{__meta__: %{source: type}, source: %{title: st}, meta: %{artists: [ artist | _]}}) do
    "#{type}#{unless is_nil(st),
          do: "/#{st}"}#{unless is_nil(artist),
          do: "/#{artist}"}"
  end


  # defp path_suffix(full, prefix) do
  #   base = byte_size(prefix)
  #   <<_::binary-size(base), rest::binary>> = full
  #   rest
  # end

end
