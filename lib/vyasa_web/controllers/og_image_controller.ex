defmodule VyasaWeb.OgImageController do
  use VyasaWeb, :controller
  # alias VyasaWeb.SourceLive.ImageGenerator
  alias Vyasa.Adapters.Binding

  action_fallback VyasaWeb.FallbackController

  @spaced_om "                       ॐ"
  @fallback_text @spaced_om <>
                   "\n" <>
                   "Come explore Indic wisdom; distilled into words." <> "\n" <> @spaced_om
  @priv_dir :code.priv_dir(:vyasa)
  @base_url Path.join([@priv_dir, "static", "images"])
  @fallback_img_url Path.join([@base_url, "fallback_thumbnail.png"])

  @doc """
  Responds with an img file.
  """
  def show(conn, %{"filename" => filename}) do
    conn
    |> put_resp_content_type("image/png")
    |> send_file(200, encode_url(filename))
  end

  def get_by_binding(%Binding{} = b) do
    with target_url <- encode_url(b),
         {:file, _, false} <- {:file, target_url, File.exists?(target_url)},
         template <- template(b),
         image <- create(target_url, template) do
      IO.inspect(image)
      target_url
    else
      {:file, url, true} -> url
      _ -> @fallback_img_url
    end
  end

  def get_by_binding(params) do
    {:ok, b} = Binding.cast(params)
    get_by_binding(b)
  end

  def encode_url(%Binding{chapter: %{no: c_no}, source: %{title: title}}) do
    "source_#{title}_#{c_no}.png"
  end

  def encode_url(%Binding{source: %{title: title}}) do
    "source_#{title}.png"
  end

  def encode_url(path) do
    System.tmp_dir() |> Path.join(path)
  end

  @doc """
  templates derived from Binding for image pipes in the future
  """

  def template(%Binding{
        chapter: %{
          no: c_no,
          title: c_title,
          translations: [%{lang: lang, target: %{title_translit: t_title}} | _]
        },
        source: %{title: title}
      }) do
    %{text: "#{Recase.to_title(title)} Chapter #{c_no}\n\
    #{c_title}\n
    #{t_title}
    ",
     lang: lang
    }
  end

  def template(%Binding{chapter: %{no: c_no, title: c_title}, source: %{title: title, lang: lang}}) do
    %{text: "#{Recase.to_title(title)} Chapter #{c_no}\n\
    #{c_title} \n
    ",
     lang: lang
    }
  end

  def template(%Binding{source: %{title: title, lang: lang}}), do: %{text: "#{Recase.to_title(title)}", lang: lang}

  def template(_) do
    @fallback_text
  end

  def create(filename, content) when is_map(content) do
    content
    |> create_thumbnail()
    |> Image.write!(encode_url(filename))
  end

  @img_bg_file_url Path.join([@base_url, "logo_with_gradient_and_stamp_1200x630.png"])
  @doc """
  Returns a thumbnail with simple text overlaid onto the logo with gradient & project stamp.
  """
  def create_thumbnail(%{text: text, lang: lang}) when is_binary(text) do
    # overall config
    dims = "1200x630"
    # caption config
    font = lang
    font_weight = 800
    caption_width = 800
    caption_height = 400
    font_size = 70
    caption_text_color = "brown"

    bg_url =
      [:code.priv_dir(:vyasa), "static", "images", "logo_with_gradient_and_stamp_1200x630.png"]
      |> Path.join()

    IO.inspect(@img_bg_file_url, label: "compiletime")
    IO.inspect(bg_url, label: "runtime")

    {:ok, base} =
      bg_url
      |> Image.open()

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
        width: caption_width,
        height: caption_height,
        font: font,
        font_weight: font_weight
      )

    thumbed
    |> Image.compose!(txt_img)
  end
end
