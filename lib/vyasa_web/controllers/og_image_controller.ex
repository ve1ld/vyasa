defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  # alias VyasaWeb.SourceLive.ImageGenerator
  alias Vyasa.Adapters.OgAdapter

  action_fallback VyasaWeb.FallbackController


  @spaced_om "                       ॐ"
  @fallback_text @spaced_om <> "\n" <> "Come explore Indic wisdom; distilled into words." <> "\n" <> @spaced_om
  @priv_dir :code.priv_dir(:vyasa)
  @base_url Path.join([@priv_dir, "static", "images"])
  @fallback_img_url Path.join([@base_url, "fallback_thumbnail.png"])

  @doc """
  Responds with an img file.
  """
  def show(conn, %{"filename" => filename}) do
    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, get_url_for_img_file(filename))
  end

  @doc """
  Returns a url based on the provided filename.
  Generates images just-in-time if the file doesn't exsit.
  If any error is encountered, fallsback to using the fallback image's url.
  """
  def get_url_for_img_file(filename) do
    # TODO: Add try-catch since this involves file-io & db querying
    case fetch_image_jit(filename) do
      {:ok, target_url} -> target_url
      {:error, _} ->
        IO.inspect(".. returning fallback img url #{@fallback_img_url}")
        @fallback_img_url
    end
  end

  @doc """
  Using the filename, returns a valid url in the tmp dir if it exists,
  else it generates (and writes) an image just-in-time and returns its url.
  """
  def fetch_image_jit(filename) do
    target_url = System.tmp_dir() |> Path.join(filename)

    if File.exists?(target_url) do
      {:ok, target_url}
    else
      case OgAdapter.get_og_content(remove_ext(filename)) do
        {:ok, text} ->
          {:ok, generate_og_image!(filename, text)}
        _ ->
          {:error, "Couldn't generate image, we shall use the fallback image instead"}
      end
    end
  end

  @doc """
  Given a filename with an extension, returns the filename without the extension.

  NOTE: doesn't check if the extension is valid or not.
  """
  def remove_ext(filename) do
    filename
    |> String.split(".")
    |> List.last() # this is the ext.
    |> (&String.split(filename, ".#{&1}")).()
    |> List.first()
  end

  # @doc """
  # Fetches the actual content, by parsing the filename.

  # For now, this shall only fetch gita-related content. Subsequently, this function may be
  # updated to support other texts and media formats.
  # """
  # def get_og_content(filename) do
  #   case OgAdapter.resolve_src_id(filename) do
  #     {:ok, :gita} -> OgAdapter.get_content(:gita, filename)
  #     _ -> {:error}
  #   end
  # end

  def generate_og_image!(filename, content \\ @fallback_text) when is_binary(content) do
    content
    |> create_thumbnail()
    |> write_opengraph_image(filename)
  end


  # writes the opengraph img to tmp dir and returns the location's url
  defp write_opengraph_image(img, filename) do
    target_url = System.tmp_dir() |> Path.join(filename)
    IO.puts(">> [write_opengraph_image] target url: #{target_url}")

    Image.write!(img, target_url)
    target_url
  end



  @img_bg_file_url Path.join([@base_url, "logo_with_gradient_and_stamp_1200x630.png"])
  @doc """
  Returns a thumbnail with simple text overlaid onto the logo with gradient & project stamp.
  """
  def create_thumbnail(text) when is_binary(text) do
    # overall config
    dims = "1200x630"
    # caption config
    font = "Gotu"
    font_weight = 800
    caption_width = 800
    caption_height = 400
    font_size = 70
    caption_text_color = "brown"

    {:ok, base} = Image.open(@img_bg_file_url)

    {:ok, thumbed} =
      base
      |> Image.thumbnail!(dims)
      |> Image.blur(sigma: 0.1)

    {:ok, txt_img} =
      Image.Text.simple_text(
        text,
        align: :left,
        font_size: font_size,
        text_fill_color: caption_text_color,
        x: :right,
        y: :top,
        autofit: true,
        width: caption_width,
        height: caption_height,
        font: font,
        font_weight: font_weight
      )

    thumbed
    |> Image.compose!(txt_img)
  end

  end
