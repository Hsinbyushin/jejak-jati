defmodule JejakJati.Repo.Migrations.CreateWorkReconciliations do
  use Ecto.Migration

  def change do
    create table(:work_reconciliations, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :left_candidate_id,
          references(:source_candidates,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :right_candidate_id,
          references(:source_candidates,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :score, :integer, null: false
      add :decision, :string, null: false
      add :reasons, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:work_reconciliations, [:left_candidate_id])
    create index(:work_reconciliations, [:right_candidate_id])

    create unique_index(
             :work_reconciliations,
             [:left_candidate_id, :right_candidate_id]
           )
  end
end
