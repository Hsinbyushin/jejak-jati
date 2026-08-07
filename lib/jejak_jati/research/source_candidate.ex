defmodule JejakJati.Research.SourceCandidate do
  @moduledoc """
  Stores a bibliographic candidate returned by an external source.

  A candidate belongs to a SourceRequest and preserves both the normalized
  bibliographic data returned by the source and the result of Jejak Jati's
  matching process.

  Candidates are not accepted bibliographic facts. They are possible matches
  that may later be accepted, rejected, or reviewed.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias JejakJati.Research.SourceRequest

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "source_candidates" do
    belongs_to :source_request, SourceRequest

    field :source_id, :string
    field :title, :string
    field :author_name, :string
    field :isbn, :string
    field :publication_year, :string
    field :publisher, :string
    field :source_url, :string

    field :score, :integer, default: 0
    field :match_reasons, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(source_candidate, attrs) do
    source_candidate
    |> cast(attrs, [
      :source_request_id,
      :source_id,
      :title,
      :author_name,
      :isbn,
      :publication_year,
      :publisher,
      :source_url,
      :score,
      :match_reasons
    ])
    |> validate_required([
      :source_request_id,
      :source_id,
      :title,
      :score
    ])
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> unique_constraint([:source_request_id, :source_id])
  end
end
