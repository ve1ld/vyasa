defmodule Vyasa.Sangh.SheafLattice do
  alias Vyasa.Sangh

  @moduledoc """
  A sheaf lattice is a flatmap that represents the tree-structure of sheafs.
  The keys in this flatmap are the labels for a sheaf and the values are the particular sheafs themselves.
  In this way, we can keep all of:
  a) root sheafs: keyed by [x] where is_binary(x)
  b) level 1 sheafs: keyed by [x, y] where is_binary(x) and is_binary(y)
  c) level 2 sheafs: keyed by [x, y, z] where is_binary(x) and is_binary(y) and is_binary(z)

  And subsequently, we can read by means of specific filters as well.
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
  Reads sheaf layers from a lattice based on the specified level and match criteria.

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
    sheaf_lattice
    |> Enum.filter(create_sheaf_lattice_filter(level, match))
    |> Enum.map(fn {_, s} -> s end)
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
end
