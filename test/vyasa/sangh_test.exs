defmodule Vyasa.SanghTest do
  use Vyasa.DataCase

  alias Vyasa.Sangh

  describe "sessions" do
    alias Vyasa.Sangh.Session

    import Vyasa.SanghFixtures

    @invalid_attrs %{id: nil}

    test "list_sessions/0 returns all sessions" do
      session = session_fixture()
      assert Sangh.list_sessions() == [session]
    end

    test "get_session!/1 returns the session with given id" do
      session = session_fixture()
      assert Sangh.get_session!(session.id) == session
    end

    test "create_session/1 with valid data creates a session" do
      valid_attrs = %{id: "7488a646-e31f-11e4-aace-600308960662"}

      assert {:ok, %Session{} = session} = Sangh.create_session(valid_attrs)
      assert session.id == "7488a646-e31f-11e4-aace-600308960662"
    end

    test "create_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sangh.create_session(@invalid_attrs)
    end

    test "update_session/2 with valid data updates the session" do
      session = session_fixture()
      update_attrs = %{id: "7488a646-e31f-11e4-aace-600308960668"}

      assert {:ok, %Session{} = session} = Sangh.update_session(session, update_attrs)
      assert session.id == "7488a646-e31f-11e4-aace-600308960668"
    end

    test "update_session/2 with invalid data returns error changeset" do
      session = session_fixture()
      assert {:error, %Ecto.Changeset{}} = Sangh.update_session(session, @invalid_attrs)
      assert session == Sangh.get_session!(session.id)
    end

    test "delete_session/1 deletes the session" do
      session = session_fixture()
      assert {:ok, %Session{}} = Sangh.delete_session(session)
      assert_raise Ecto.NoResultsError, fn -> Sangh.get_session!(session.id) end
    end

    test "change_session/1 returns a session changeset" do
      session = session_fixture()
      assert %Ecto.Changeset{} = Sangh.change_session(session)
    end
  end
end
