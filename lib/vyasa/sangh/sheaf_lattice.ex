defmodule Vyasa.Sangh.SheafLattice do
  alias Vyasa.Sangh
  alias Vyasa.Sangh.{Sheaf}
  alias EctoLtree.LabelTree, as: Ltree
  alias VyasaWeb.Context.Components.UiState.Sheaf, as: SheafUiState

  @moduledoc """
  A sheaf lattice is a flatmap that represents the tree-structure of sheafs.
  The keys in this flatmap are the labels for a sheaf and the values are the particular sheafs themselves.
  In this way, we can keep all of:
  a) root sheafs: keyed by [x] where is_binary(x)
  b) level 1 sheafs: keyed by [x, y] where is_binary(x) and is_binary(y)
  c) level 2 sheafs: keyed by [x, y, z] where is_binary(x) and is_binary(y) and is_binary(z)

  And subsequently, we can read by means of specific filters as well.

  NOTE: this preloads the marks in each sheaf.
  """
  def create_complete_sheaf_lattice(sangh_id) when is_binary(sangh_id) do
    root_sheafs =
      sangh_id
      |> Sangh.get_root_sheafs_by_session()
      |> Enum.filter(fn s -> s.traits == ["published"] end)

    [0, 1, 2]
    |> Enum.flat_map(fn level ->
      root_sheafs
      |> Enum.map(fn sheaf -> to_string(sheaf.path) end)
      |> Enum.flat_map(fn sheaf_id ->
        Sangh.get_child_sheafs_by_session(sangh_id, sheaf_id, level)
      end)
      |> Enum.map(fn s -> {s.path.labels, s} end)
    end)
    |> Enum.into(%{})
  end

  # @doc """
  # Inserts a particular mark into a particular sheaf in the lattice.

  # Intent is that it gets used when creating a mark in the discuss mode.
  # TODO: figure out what is the best place to put this?
  # """
  # def insert_mark_into_sheaf_in_lattice(
  #       %{} = lattice,
  #       %Ltree{labels: lattice_key} = _sheaf_path,
  #       %Mark{id: mark_id, body: body} = mark
  #     ) do
  #   %Sheaf{
  #     marks: rest_marks
  #   } = target_sheaf = lattice |> Map.get(lattice_key)

  #   updated_new_mark = %Mark{
  #     mark
  #     | id: if(not is_nil(mark_id), do: Ecto.UUID.generate(), else: mark_id),
  #       order: Mark.get_next_order(rest_marks),
  #       body: body,
  #       state: :live
  #   }

  #   updated_sheaf = %Sheaf{target_sheaf | marks: [updated_new_mark | rest_marks]}

  #   socket
  #   |> register_sheaf(updated_sheaf)
  # end

  @doc """
  Inserts sheaf into sheaf state lattice, overwrites existing sheaf
  if exists.
  """
  def insert_sheaf_into_lattice(
        %{} = lattice,
        %Sheaf{
          path: %Ltree{labels: path_labels}
        } = sheaf
      ) do
    lattice |> Map.put(path_labels, sheaf)
  end

  @doc """
  Inserts %SheafUiState{} into sheaf state lattice, overwrites existing sheaf
  if exists.
  Intended to be used @ the point of init, rather than when incrementally updating things.
  """
  def insert_sheaf_into_ui_lattice(
        %{} = ui_lattice,
        %Sheaf{
          path: %Ltree{labels: path_labels}
        } = sheaf
      ) do
    ui_lattice |> Map.put(path_labels, sheaf |> SheafUiState.get_initial_ui_state())
  end

  @doc """
  Removes sheaf from state lattice, expected to be used in deletes.
  """
  def remove_sheaf_from_lattice(
        %{} = lattice,
        %Sheaf{
          path: %Ltree{labels: path_labels}
        } = _old_sheaf
      ) do
    lattice |> Map.delete(path_labels)
  end

  @doc """
  Removes sheaf from ui lattice, expected to be used in deletes.
  """
  def remove_sheaf_from_ui_lattice(
        %{} = ui_lattice,
        %Sheaf{
          path: %Ltree{labels: _path_labels}
        } = old_sheaf
      ) do
    ui_lattice |> remove_sheaf_from_lattice(old_sheaf)
  end

  # TODO implement wrappers for the other sheaf ui state changes:
  # 1. register and deregister mark
  # 2. toggles:
  #    a) toggle_is_editable_marks ==> for a particular sheaf in the lattice
  #    b) toggle_show_sheaf_modal? ==> for a particular sheaf in the lattice
  #    c) toggle_marks_is_expanded_view? ==> for a particular sheaf in the lattice
  #    d) toggle_is_editing_mark_content(sheaf, mark_id) ==> for a particular mark within a particular sheaf

  @doc """
  Reads sheaf layers from a lattice based on the specified level and match criteria.

  NOTE: because we are having a max depth of 3, this shall return an empty list if argument for level > 2 (zero-indexed).

  ## Examples

  # Fetch all sheafs in a particular level
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice)
      # equivalent to:
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 0, nil)

      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 1, nil)

      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 2, nil)

  # Fetch based on specific matches of a single label
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 0, "cf27deab")

      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 1, "65c1ac0c")

      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 2, "56c369e4")

  # Fetch based on complete matches
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 1, ["c9cbcb0c", "65c1ac0c"])

      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 2, ["c9cbcb0c", "f91bac0d", "56c369e4"])

  # Fetch immediate children based on particular parent
  # Fetch immediate children of a specific level 0 node:
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 1, ["cf27deab", nil])

  # Fetch immediate children of a specific level 1 node:
      iex> SheafLattice.read_sheaf_lattice(sheaf_lattice, 2, ["c9cbcb0c", "65c1ac0c", nil])
  """

  def read_sheaf_lattice(%{} = sheaf_lattice, level \\ 0, match \\ nil) do
    case level > 2 do
      true ->
        []

      false ->
        sheaf_lattice
        |> Enum.filter(create_sheaf_lattice_filter(level, match))
        |> Enum.map(fn {_, s} -> s end)
    end
  end

  # fetches all sheafs in level 0:
  defp create_sheaf_lattice_filter(0, nil) do
    fn
      {[_], _sheaf} -> true
      _ -> false
    end
  end

  # fetches all sheafs in level 1:
  defp create_sheaf_lattice_filter(1, nil) do
    fn
      {[_, a], _sheaf} when is_binary(a) -> true
      _ -> false
    end
  end

  # fetches all sheafs in level 2:
  defp create_sheaf_lattice_filter(2, nil) do
    fn
      {[a | [b | [c]]], _sheaf} when is_binary(a) and is_binary(b) and is_binary(c) -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 0
  defp create_sheaf_lattice_filter(0, m) when is_binary(m) do
    fn
      {[^m], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 1
  defp create_sheaf_lattice_filter(1, m) when is_binary(m) do
    fn
      {[_, ^m], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 2
  defp create_sheaf_lattice_filter(2, m) when is_binary(m) do
    fn
      {[_ | [_ | [^m]]], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 1, by matching labels completely
  defp create_sheaf_lattice_filter(1, [a, b]) when is_binary(a) and is_binary(b) do
    fn
      {[^a, ^b], _sheaf} -> true
      _ -> false
    end
  end

  # fetches particular sheaf from level 2, by matching labels completely
  defp create_sheaf_lattice_filter(2, [a, b, c])
       when is_binary(a) and is_binary(b) and is_binary(c) do
    fn
      {[^a, ^b, ^c], _sheaf} -> true
      _ -> false
    end
  end

  # fetches all the immeidate children (level 1) of a root sheaf (level 2)
  defp create_sheaf_lattice_filter(1, [a, b]) when is_binary(a) and is_nil(b) do
    fn
      {[^a, _], _sheaf} when is_binary(a) -> true
      _ -> false
    end
  end

  # fetches all the immediate children (level 2) of a level 1 sheaf
  defp create_sheaf_lattice_filter(2, [a, b, nil]) when is_binary(a) and is_binary(b) do
    fn
      {[^a, ^b, _], _sheaf} -> true
      _ -> false
    end
  end

  # fallthrough
  # QQ: not sure if i should be removing this fallback
  # too sleepy to figure out
  # TODO: what to do here?
  defp create_sheaf_lattice_filter(_, _) do
    fn _ -> true end
  end

  def get_ui_from_lattice(
        %{} = sheaf_ui_lattice,
        %Sheaf{path: path} = sheaf
      )
      when not is_nil(path) do
    sheaf_ui_lattice |> Map.get(sheaf |> Sheaf.get_path_labels(), nil)
  end
end
