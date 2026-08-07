defmodule JejakJati.Research.SourceRequest do
  @moduledoc """
  Records the outcome of querying one external source for a research run.

  A SourceRequest belongs to exactly one ResearchRun and represents the
  technical and bibliographic outcome of consulting a particular source.

  It deliberately stores a summary rather than the complete source response.
  Raw source records and individual evidence assertions will be introduced
  separately later.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias JejakJati.Research.{ResearchRun, SourceCandidate}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "source_requests" do
    belongs_to :research_run, ResearchRun

    has_many :source_candidates, SourceCandidate
    field :source, Ecto.Enum, values: [:dnb, :open_library]

    field :status, Ecto.Enum,
      values: [:pending, :running, :succeeded, :failed],
      default: :pending

    field :candidate_count, :integer, default: 0
    field :best_score, :integer

    field :decision, Ecto.Enum, values: [:strong_match, :review, :no_match]

    field :error_message, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(source_request, attrs) do
    source_request
    |> cast(attrs, [
      :research_run_id,
      :source,
      :status,
      :candidate_count,
      :best_score,
      :decision,
      :error_message
    ])
    |> validate_required([
      :research_run_id,
      :source,
      :status
    ])
    |> validate_number(:candidate_count, greater_than_or_equal_to: 0)
    |> unique_constraint([:research_run_id, :source])
  end
end
