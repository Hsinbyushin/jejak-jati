defmodule JejakJati.Repo.Migrations.CreateSourceRequests do
  use Ecto.Migration

  def change do
    create table(:source_requests, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :research_run_id,
          references(:research_runs,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :source, :string, null: false
      add :status, :string, null: false, default: "pending"

      add :candidate_count, :integer, null: false, default: 0
      add :best_score, :integer
      add :decision, :string
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create index(:source_requests, [:research_run_id])
    create unique_index(:source_requests, [:research_run_id, :source])
  end
end
