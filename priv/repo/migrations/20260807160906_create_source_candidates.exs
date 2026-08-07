defmodule JejakJati.Repo.Migrations.CreateSourceCandidates do
  use Ecto.Migration

  def change do
    create table(:source_candidates, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :source_request_id,
          references(:source_requests,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :source_id, :string, null: false
      add :title, :text, null: false
      add :author_name, :string
      add :isbn, :string
      add :publication_year, :string
      add :publisher, :string
      add :source_url, :text

      add :score, :integer, null: false, default: 0
      add :match_reasons, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:source_candidates, [:source_request_id])

    create unique_index(
             :source_candidates,
             [:source_request_id, :source_id]
           )
  end
end
