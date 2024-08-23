defmodule VyasaWeb.AdminLive.Source do
  use Backpex.LiveResource,
    layout: {VyasaWeb.Layouts, :admin},
    # fluid?: false,
    schema: Vyasa.Written.Source,
    repo: Vyasa.Repo,
    update_changeset: &Vyasa.Written.Source.mutate_changeset/2,
    create_changeset: &Vyasa.Written.Source.gen_changeset/2,
    pubsub: Vyasa.PubSub,
    topic: "admin::sources",
    event_prefix: "admin::sources_"

  @impl Backpex.LiveResource
  def singular_name, do: "Source"

  @impl Backpex.LiveResource
  def plural_name, do: "Sources"

  @impl Backpex.LiveResource
  def fields do
    # ref docs on fields: https://hexdocs.pm/backpex/what-is-a-field.html
    [
      title: %{
        module: Backpex.Fields.Text,
        label: "Title"
      },
      views: %{
        module: Backpex.Fields.Number,
        label: "Views"
      }
    ]
  end
end
