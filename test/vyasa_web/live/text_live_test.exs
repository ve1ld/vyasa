defmodule VyasaWeb.TextLiveTest do
  use VyasaWeb.ConnCase

  import Phoenix.LiveViewTest
  import Vyasa.WrittenFixtures

  @create_attrs %{title: "some title"}
  @update_attrs %{title: "some updated title"}
  @invalid_attrs %{title: nil}

  defp create_text(_) do
    text = text_fixture()
    %{text: text}
  end

  describe "Index" do
    setup [:create_text]

    test "lists all texts", %{conn: conn, text: text} do
      {:ok, _index_live, html} = live(conn, ~p"/texts")

      assert html =~ "Listing Texts"
      assert html =~ text.title
    end

    test "saves new text", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/texts")

      assert index_live |> element("a", "New Text") |> render_click() =~
               "New Text"

      assert_patch(index_live, ~p"/texts/new")

      assert index_live
             |> form("#text-form", text: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#text-form", text: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/texts")

      html = render(index_live)
      assert html =~ "Text created successfully"
      assert html =~ "some title"
    end

    test "updates text in listing", %{conn: conn, text: text} do
      {:ok, index_live, _html} = live(conn, ~p"/texts")

      assert index_live |> element("#texts-#{text.id} a", "Edit") |> render_click() =~
               "Edit Text"

      assert_patch(index_live, ~p"/texts/#{text}/edit")

      assert index_live
             |> form("#text-form", text: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#text-form", text: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/texts")

      html = render(index_live)
      assert html =~ "Text updated successfully"
      assert html =~ "some updated title"
    end

    test "deletes text in listing", %{conn: conn, text: text} do
      {:ok, index_live, _html} = live(conn, ~p"/texts")

      assert index_live |> element("#texts-#{text.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#texts-#{text.id}")
    end
  end

  describe "Show" do
    setup [:create_text]

    test "displays text", %{conn: conn, text: text} do
      {:ok, _show_live, html} = live(conn, ~p"/texts/#{text}")

      assert html =~ "Show Text"
      assert html =~ text.title
    end

    test "updates text within modal", %{conn: conn, text: text} do
      {:ok, show_live, _html} = live(conn, ~p"/texts/#{text}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Text"

      assert_patch(show_live, ~p"/texts/#{text}/show/edit")

      assert show_live
             |> form("#text-form", text: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#text-form", text: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/texts/#{text}")

      html = render(show_live)
      assert html =~ "Text updated successfully"
      assert html =~ "some updated title"
    end
  end
end
