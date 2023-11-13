defmodule Vyasa.WrittenTest do
  use Vyasa.DataCase

  alias Vyasa.Written

  describe "texts" do
    alias Vyasa.Written.Text

    import Vyasa.WrittenFixtures

    @invalid_attrs %{title: nil}

    test "list_texts/0 returns all texts" do
      text = text_fixture()
      assert Written.list_texts() == [text]
    end

    test "get_text!/1 returns the text with given id" do
      text = text_fixture()
      assert Written.get_text!(text.id) == text
    end

    test "create_text/1 with valid data creates a text" do
      valid_attrs = %{title: "some title"}

      assert {:ok, %Text{} = text} = Written.create_text(valid_attrs)
      assert text.title == "some title"
    end

    test "create_text/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Written.create_text(@invalid_attrs)
    end

    test "update_text/2 with valid data updates the text" do
      text = text_fixture()
      update_attrs = %{title: "some updated title"}

      assert {:ok, %Text{} = text} = Written.update_text(text, update_attrs)
      assert text.title == "some updated title"
    end

    test "update_text/2 with invalid data returns error changeset" do
      text = text_fixture()
      assert {:error, %Ecto.Changeset{}} = Written.update_text(text, @invalid_attrs)
      assert text == Written.get_text!(text.id)
    end

    test "delete_text/1 deletes the text" do
      text = text_fixture()
      assert {:ok, %Text{}} = Written.delete_text(text)
      assert_raise Ecto.NoResultsError, fn -> Written.get_text!(text.id) end
    end

    test "change_text/1 returns a text changeset" do
      text = text_fixture()
      assert %Ecto.Changeset{} = Written.change_text(text)
    end
  end
end
