defmodule Vyasa.Sangh.SheafLattice do
  alias Vyasa.Sangh
  alias Vyasa.Sangh.{Sheaf, Mark}
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

  This module provides context functions to interact with such lattices. We should keep in mind that
  the functions defined within this context ONLY modify the respective structs that the lattices hold,
  and have no other side-effects. For example, there shall never be any DB writes happening from these
  functions.
  """

  @doc """
  Represents all the sheafs in the sangh session using the lattice.
  This shall be used in index actions, hence it has no filters.
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

  @doc """
  Inserts sheaf into sheaf state lattice, overwrites existing sheaf
  if it exists.
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
  Swaps out the current sheaf for a particular key in the lattice to the updated_sheaf.
  """
  def update_sheaf_in_lattice(
        %{} = lattice,
        lattice_key,
        %Sheaf{} = updated_sheaf
      )
      when is_list(lattice_key) do
    lattice |> Map.put(lattice_key, updated_sheaf)
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

  @doc """
  Registers a particular mark within a particular sheaf.

  TODO: use this when wiring up the mark-creation / deletion events within discuss mode
  """
  def ui_register_mark(
        %{} = ui_lattice,
        lattice_key,
        mark_id
      )
      when is_list(lattice_key) and is_binary(mark_id) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.register_mark(mark_id)
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  @doc """
  De-Registers a particular mark within a particular sheaf.

  TODO: use this when wiring up the mark-creation / deletion events within discuss mode
  """
  def ui_deregister_mark(
        %{} = ui_lattice,
        lattice_key,
        mark_id
      )
      when is_list(lattice_key) and is_binary(mark_id) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.deregister_mark(mark_id)
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  @doc """
  Toggles the mark ui for a particular mark in a particular sheaf in the lattice.
  """
  def toggle_is_editing_mark_content?(
        %{} = ui_lattice,
        lattice_key,
        mark_id
      )
      when is_list(lattice_key) and is_binary(mark_id) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_is_editing_mark_content?(mark_id)
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def toggle_show_sheaf_modal?(
        %{} = ui_lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_show_sheaf_modal?()
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def set_show_sheaf_modal?(%{} = ui_lattice, lattice_key, value \\ true)
      when is_list(lattice_key) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.set_show_sheaf_modal?(value)
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def toggle_sheaf_is_focused?(
        %{} = ui_lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_sheaf_is_focused?()
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def toggle_is_editable_marks(
        %{} = ui_lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_is_editable_marks?()
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def toggle_marks_display_collapsibility(
        %{} = ui_lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_marks_is_expanded_view()
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  @doc """
  Toggles the is_expanded? flag for a particular sheaf, as keyed by the
  lattice_key.

  If no such entry exists, returns the original ui_lattice without any alteration.
  """
  def toggle_sheaf_is_expanded?(
        %{} = ui_lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    IO.inspect(lattice_key, label: "toggle_sheaf_is_expanded? lattice key that is a string:")
    sheaf_ui = ui_lattice |> Map.get(lattice_key, nil)

    case sheaf_ui do
      ui when not is_nil(ui) ->
        updated_sheaf_ui = ui |> SheafUiState.toggle_sheaf_is_expanded?()
        ui_lattice |> Map.put(lattice_key, updated_sheaf_ui)

      _ ->
        ui_lattice
    end
  end

  def recurse_sheaf_is_expanded?(ui_lattice, lattice_key) do
    lattice_key
    |> hist_reduce(ui_lattice, fn elem, lat -> toggle_sheaf_is_expanded?(lat, elem) end)
  end

  def hist_reduce(list, initial, fun) when is_list(list) do
    list
    |> Enum.reduce({initial, []}, fn elem, {acc, history} ->
      new_history = [elem | history]
      new_acc = fun.(new_history, acc)
      {new_acc, new_history}
    end)
    |> elem(0)
  end


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

  TODO: @ks0m1c could you help me use the Access pattern for this, I think it's much faster if you do it,
  will be a tiny PR for it as well.
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

  @doc """
  Returns sheafs from the lattice only if they are non-draft.
  """
  def read_published_from_sheaf_lattice(%{} = sheaf_lattice, level \\ 0, match \\ nil) do
    sheaf_lattice
    |> read_sheaf_lattice(level, match)
    |> Enum.reject(fn %Sheaf{traits: traits} -> "draft" in traits end)
    # TODO: to verify this, may not be correct
    |> sort_sheaf_lattice_entries_chrono()
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

  # fallthrough -- WARNING: any failure will happen silently
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

  def get_sheaf_from_lattice(
        %{} = lattice,
        lattice_key
      )
      when is_list(lattice_key) do
    lattice |> Map.get(lattice_key, nil)
  end

  def edit_mark_content_within_sheaf(
        %{} = lattice,
        lattice_key,
        mark_id,
        input
      )
      when is_list(lattice_key) and is_binary(mark_id) and is_binary(input) do
    %Sheaf{
      marks: old_marks
    } = old_sheaf = lattice |> get_sheaf_from_lattice(lattice_key)

    {[old_mark | _] = _old_versions_of_changed, updated_marks} =
      get_and_update_in(
        old_marks,
        [Access.filter(&match?(%Mark{id: ^mark_id}, &1))],
        &{&1, Map.put(&1, :body, input)}
      )

    old_mark |> Vyasa.Draft.update_mark(%{body: input})

    lattice |> update_sheaf_in_lattice(lattice_key, %Sheaf{old_sheaf | marks: updated_marks})
  end

  def sort_sheaf_lattice_entries_chrono([{label, %Sheaf{}} | _] = entries) when is_list(label) do
    entries |> Enum.sort_by(fn {_, %Sheaf{} = sheaf} -> sheaf.inserted_at end, :desc)
  end

  def sort_sheaf_lattice_entries_chrono(entries) do
    entries
  end
end
