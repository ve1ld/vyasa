defmodule Vyasa.Corpus.Transliterator.Tamil do
  @moduledoc """
  Provides functionality for transliterating Tamil text to Roman script.
  """
  @external_resource Path.join(:code.priv_dir(:vyasa), "static/rules/tamil.json")
  @rules Path.join(:code.priv_dir(:vyasa), "static/rules/tamil.json")
    |> File.read!()
    |> Jason.decode!()

  # Constants
  @vallinam ["க", "ச", "ட", "த", "ப", "ற"]
  @mellinam ["ங", "ஞ", "ண", "ந", "ம", "ன"]
  @idaiyinam ["ய", "ர", "ல", "வ", "ழ", "ள"]
  @word_boundaries [" ", "\n", ",", ";", ":", "'", "-", "_", "(", ")", ".", "$", "@", "#", "%", "*"]

@doc """
  Transliterates Tamil text to Roman script.
  """
  def transliterate(tamil_text) do
    # First handle special cases
    special_cases = Map.get(@rules, "special_case", %{})
    text_with_special_cases = replace_special_cases(tamil_text, special_cases)

    # Then do the main transliteration
    do_transliterate(String.graphemes(text_with_special_cases), @rules, "", true)
  end

  # Handle special case replacements
  defp replace_special_cases(text, special_cases) do
    Enum.reduce(special_cases, text, fn {pattern, replacement}, acc ->
      String.replace(acc, pattern, replacement)
    end)
  end

  # Main transliteration recursive function
  defp do_transliterate([], _rules, acc, _word_start), do: String.trim(acc)

  defp do_transliterate([char | rest], rules, acc, word_start) do
    case process_character(char, rest, rules, word_start) do
      {:processed, new_text, chars_to_skip} ->
        next_word_start = if chars_to_skip > 0 do
          Enum.at(rest, chars_to_skip - 1) in @word_boundaries
        else
          char in @word_boundaries
        end

        do_transliterate(
          Enum.drop(rest, chars_to_skip),
          rules,
          acc <> new_text,
          next_word_start
        )

      {:unprocessed, new_text} ->
        do_transliterate(
          rest,
          rules,
          acc <> new_text,
          char in @word_boundaries
        )
    end
  end

  @doc """
  Processes a single character or character combination for transliteration.
  """
  def process_character(char, rest, rules, word_start) do
    letter_rules = Map.get(rules, "letter_rule", %{})

    cond do
      # Handle two-character combinations
      length(rest) >= 1 and Map.has_key?(letter_rules, char <> hd(rest)) ->
        tam_word = char <> hd(rest)
        prev_chars = if length(rest) >= 2, do: Enum.take(rest, 2) |> Enum.join(), else: ""
        next_chars = Enum.take(rest, 2)

        result = olipeyarppu(
          word_start,
          tam_word,
          prev_chars,
          Enum.at(next_chars, 1) || "",
          hd(next_chars) || "",
          rules
        )

        {:processed, result, 1}

      # Handle single characters
      Map.has_key?(letter_rules, char) ->
        next_char = if length(rest) > 0, do: hd(rest), else: ""
        prev_chars = if length(rest) >= 2, do: Enum.take(rest, 2) |> Enum.join(), else: ""
        next_next_char = if length(rest) > 1, do: Enum.at(rest, 1), else: ""

        result = olipeyarppu(
          word_start,
          char,
          prev_chars,
          next_next_char,
          next_char,
          rules
        )

        {:processed, result, 0}

      true ->
        {:unprocessed, char}
    end
  end

  @doc """
  Combines a consonant with vowel signs.
  Returns a list of strings.
  """
  def extras_comb(letter, extras) do
    # Convert the extras map to a list of keys and concatenate each with the letter
    extras
    |> Map.keys()
    |> Enum.map(&(letter <> &1))
  end

  @doc """
  Main transliteration rules implementation.
  """
  def olipeyarppu(word_start, tam_word, prev_comb, next_next_char, _next_char, rules) do
    ka_rule = Map.get(rules, "ka_rule", %{})
    #sa_rule = Map.get(rules, "sa_rule", %{})
    ta_rule = Map.get(rules, "ta_rule", %{})
    pa_rule = Map.get(rules, "pa_rule", %{})
    tha_rule = Map.get(rules, "tha_rule", %{})
    extras = Map.get(rules, "extras", %{})
    letter_rules = Map.get(rules, "letter_rule", %{})

    cond do
      word_start ->
        cond do
          tam_word in extras_comb("க", extras) -> Map.get(ka_rule, tam_word, "")
          tam_word in extras_comb("த", extras) -> Map.get(tha_rule, tam_word, "")
          tam_word in Enum.drop(extras_comb("ட", extras), 2) -> Map.get(ta_rule, tam_word, "")
          tam_word in extras_comb("ப", extras) -> Map.get(pa_rule, tam_word, "")
          true -> Map.get(letter_rules, tam_word, "")
        end

      tam_word == "க" and prev_comb == "று" ->
        "ka"

      prev_comb in Enum.map(@vallinam ++ @idaiyinam ++ @mellinam ++ ["ஸ", "ஷ"], &(&1 <> "்")) ->
        handle_special_combinations(tam_word, prev_comb, rules)

      tam_word == "ற்" and next_next_char == "ற" ->
        "t"

      true ->
        Map.get(letter_rules, tam_word, "")
    end
  end

  # Helper function to handle special combinations
  defp handle_special_combinations(tam_word, prev_comb, rules) do
    letter_rules = Map.get(rules, "letter_rule", %{})
    extras = Map.get(rules, "extras", %{})

    cond do
      prev_comb == "ன்" ->
        case tam_word do
          "று" -> "dru"
          "றி" -> "dri"
          "ற" -> "dra"
          "றை" -> "drai"
          _ -> if tam_word in extras_comb("ப", extras),
               do: Map.get(letter_rules, tam_word, ""),
               else: ""
        end

      prev_comb in ["க்", "ச்", "ட்", "த்", "ப்", "ற்", "ஷ்", "ஸ்"] ->
        [
          Map.get(rules["ka_rule"] || %{}, tam_word, ""),
          Map.get(rules["sa_rule"] || %{}, tam_word, ""),
          Map.get(rules["ta_rule"] || %{}, tam_word, ""),
          Map.get(rules["tha_rule"] || %{}, tam_word, ""),
          Map.get(rules["pa_rule"] || %{}, tam_word, "")
        ]
        |> Enum.join()

      prev_comb in ["ஞ்", "ங்"] ->
        handle_nasal_combinations(tam_word, rules)

      true ->
        Map.get(letter_rules, tam_word, "")
    end
  end

  # Helper function to handle nasal combinations
  defp handle_nasal_combinations(tam_word, rules) do
    extras = Map.get(rules, "extras", %{})

    extras
    |> Enum.find_value("", fn {key, value} ->
      if tam_word in Enum.map(@vallinam, &(&1 <> key)), do: value, else: nil
    end)
  end
end
