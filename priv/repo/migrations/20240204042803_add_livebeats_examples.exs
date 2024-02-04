defmodule Vyasa.Repo.Migrations.AddLivebeatsExamples do
  use Ecto.Migration

  def change do
    create table(:songs) do
      add :album_artist, :string, virtual: true
      add :artist, :string, null: false, virtual: true
      add :duration, :integer, default: 0, null: false, virtual: true
      add :status, :integer, null: false, default: 1, virtual: true
      add :played_at, :utc_datetime, virtual: true
      add :paused_at, :utc_datetime, virtual: true
      add :title, :string, null: false, virtual: true
      add :attribution, :string, virtual: true
      add :mp3_url, :string, null: false, virtual: true
      add :mp3_filename, :string, null: false, virtual: true
      add :mp3_filepath, :string, null: false, virtual: true
      add :date_recorded, :naive_datetime, virtual: true
      add :date_released, :naive_datetime, virtual: true
      # add :user_id, references(:users, on_delete: :nothing)
      # add :genre_id, references(:genres, on_delete: :nothing)

      timestamps()
    end

    # create unique_index(:songs, [:user_id, :title, :artist])
    # create index(:songs, [:user_id])
    # create index(:songs, [:genre_id])
    # create index(:songs, [:status])
  end
end
