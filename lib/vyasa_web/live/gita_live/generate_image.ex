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
  def generate_opengraph_image!(filename, content \\ @fallback_text) do
      content
      |> generate_svg()
      |> write_opengraph_image(filename)
  end

  # NOTE: The fs-write is a side-effect here
  defp write_opengraph_image(svg, filename) do
    {img, _} = Operation.svgload_buffer!(svg)

    System.tmp_dir()
    |> Path.join(filename)
    |> tap(fn target_url -> Image.write(img, target_url) end)
  end

  defp generate_svg(content) do
      content
      |> ImageGenerator.wrap_text(@col_width)
      |> Enum.with_index()
      |> Enum.map(fn
        {line, idx} -> get_svg_for_text(line, idx)
      end)
      |> Enum.join("")
      |> gen_text_svg()
  end

  # Rudimentary function that generates svg, given the svg text nodes that should be interspersed.
  defp gen_text_svg(text_nodes) do
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
    svg_precursor <> text_nodes <> svg_end
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

    # TODO: the accumulator pattern here can be cleaner, using pattern matching. Ref: https://github.com/ve1ld/vyasa/pull/27/files#r1477036476
    Enum.reduce(
      words,
      [],
      fn word, acc_lines ->
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
