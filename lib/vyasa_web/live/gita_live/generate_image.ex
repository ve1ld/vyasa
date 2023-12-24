defmodule VyasaWeb.GitaLive.ImageGenerator do
  @moduledoc """
  Contains logic for creating images, initially for opengraph purposes mainly.
  """
  @fallback_text "Gita -- The Song Celestial"
  @col_width 20
  alias VyasaWeb.GitaLive.ImageGenerator
  alias Vix.Vips.Operation

  @doc """
    Returns a url string that can be used for the open-graph image meta-tag.
    Currently stores images locally in a temp directory.
    """
  def generate_opengraph_image(filename, title \\ @fallback_text) do
        url =
      title
      |> generate_svg()
      |> write_opengraph_image(filename)

    url
  end

  defp write_opengraph_image(svg, filename) do
    target_url = System.tmp_dir() |> Path.join(filename)
    IO.puts(">> [write_opengraph_image] target url: #{target_url}")
    {image, _} = Operation.svgload_buffer!(svg)

    Image.write!(image, target_url)
    target_url
  end

  defp generate_svg(title) do
    svg_text_nodes =
      title
      |> ImageGenerator.wrap_text(@col_width)
      |> Enum.with_index()
      |> Enum.map(fn
        {line, idx} -> get_svg_for_text(line, idx)
      end)
      |> Enum.join("")

    svg_precursor = """
    <svg viewbox="0 0 1200 600" width="1200px" height="600px" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient y2="1" x2="1" y1="0.14844" x1="0.53125" id="gradient">
         <stop offset="0" stop-opacity="0.99609" stop-color="#5b21b6"/>
         <stop offset="0.99219" stop-opacity="0.97656" stop-color="#ff8300"/>
        </linearGradient>
      </defs>
      <g>
        <rect stroke="#000" height="800px" width="1800px" y="0" x="0" stroke-width="0" fill="url(#gradient)"/>
    """

    svg_end = """
       </g>
    </svg>
    """
    svg = svg_precursor <> svg_text_nodes <> svg_end
    svg
  end

  defp get_svg_for_text(text, offset) do
    initial_y = 250
    vert_line_space = 90
    y_resolved = Integer.to_string(initial_y + vert_line_space * offset)

    """
    <text textLength="500px" lengthAdjust="spacingAndGlyphs" font-style="normal" font-weight="normal" xml:space="preserve" text-anchor="start" font-family="Gotu" font-size="70" y="#{y_resolved}" x="100" stroke-width="0" stroke="#000" fill="#f8fafc">#{text}</text>
    """
  end

  @doc """
    Manually wraps a text to width of size @col_width.
  """
  def wrap_text(text, col_length \\ @col_width) do


    words = String.split(text, " ")

    Enum.reduce(words, [], fn word, acc_lines ->
      IO.puts("[word:] #{word}")
      curr_line = List.last(acc_lines, "")
      new_combined_line = curr_line <> " " <> word
      has_space_in_curr_line = String.length(new_combined_line) <= col_length

      if has_space_in_curr_line do
        if acc_lines == [] do
          [word]
        else
          List.replace_at(acc_lines, length(acc_lines) - 1, new_combined_line)
        end
      else
        acc_lines ++ [word]
      end
    end)
  end
end
