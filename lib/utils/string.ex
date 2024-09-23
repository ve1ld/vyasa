defmodule Utils.String do
  @moduledoc """
  Contains functions useful for string operations, that need not be
  web or server-specific.
  """
  @doc """
  Inflexor logic that humanises snake_case string then converts to title case.
  """
  def to_title_case(value) when is_binary(value),
    do: Recase.to_title(value)

  @doc """
  Converts a module name to an HTML selector format.

  The module name is expected to be in the form of a module atom (e.g., `VyasaWeb.Context.Read`).
  The function extracts the last part of the module name and checks if it is in PascalCase.
  If valid, it converts the name to kebab-case format.

  ## Examples

      iex> VyasaWeb.Utils.module_to_selector(VyasaWeb.Context.Read)
      "read-context"

      iex> VyasaWeb.Utils.module_to_selector(VyasaWeb.Content.InvalidName)
      ** (ArgumentError) Last element of the module name must be in PascalCase
  """
  def module_to_selector(module) when is_atom(module) do
    simple_module_name =
      module
      |> Atom.to_string()
      |> String.split(".")
      |> List.last()

    simple_module_name
    |> pascal_case?()
    |> case do
      true ->
        simple_module_name
        # converts from PascalCase to snake_case
        |> Inflex.underscore()
        |> String.replace("_", "-")

      false ->
        raise ArgumentError, "Last element of the module name must be in PascalCase"
    end
  end

  @doc """
  Checks if a string is in PascalCase.

  ## Examples

      iex> MyApp.Utils.pascal_case?("HelloWorld")
      true

      iex> MyApp.Utils.pascal_case?("helloWorld")
      false

      iex> MyApp.Utils.pascal_case?("Hello_world")
      false

  """
  def pascal_case?(string) when is_binary(string) do
    pascal_case_regex = ~r/^[A-Z][a-zA-Z0-9]*$/

    string
    |> String.match?(pascal_case_regex)
  end
end
