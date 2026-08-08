defmodule JejakJati.Research.WorkReconciliation do
  @moduledoc """
  Represents a comparison between bibliographic candidates from
  different sources.

  A reconciliation records the evidence Jejak Jati used to estimate
  whether two source candidates describe the same underlying work.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias JejakJati.Research.SourceCandidate

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "work_reconciliations" do
    belongs_to :left_candidate, SourceCandidate
    belongs_to :right_candidate, SourceCandidate

    field :score, :integer

    field :decision, Ecto.Enum, values: [:same_work, :review, :different_work]

    field :reasons, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(reconciliation, attrs) do
    reconciliation
    |> cast(attrs, [
      :left_candidate_id,
      :right_candidate_id,
      :score,
      :decision,
      :reasons
    ])
    |> validate_required([
      :left_candidate_id,
      :right_candidate_id,
      :score,
      :decision,
      :reasons
    ])
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> validate_different_candidates()
    |> foreign_key_constraint(:left_candidate_id)
    |> foreign_key_constraint(:right_candidate_id)
    |> unique_constraint([:left_candidate_id, :right_candidate_id])
  end

  defp validate_different_candidates(changeset) do
    left = get_field(changeset, :left_candidate_id)
    right = get_field(changeset, :right_candidate_id)

    if left && right && left == right do
      add_error(
        changeset,
        :right_candidate_id,
        "must be different from left candidate"
      )
    else
      changeset
    end
  end
end
