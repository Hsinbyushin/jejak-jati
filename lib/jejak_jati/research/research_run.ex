defmodule JejakJati.Research.ResearchRun do
  alias JejakJati.Research.SourceRequest
  alias JejakJati.Research.Person
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "research_runs" do
    field :title, :string
    field :author_name, :string
    field :isbn, :string

    field :status, Ecto.Enum,
      values: [:pending, :running, :review, :completed, :failed],
      default: :pending

    has_many :source_requests, SourceRequest
    belongs_to :person, Person

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(research_run, attrs) do
    research_run
    |> cast(attrs, [:title, :author_name, :isbn, :status, :person_id])
    |> validate_required([:title, :author_name])
    |> validate_length(:title, min: 1, max: 500)
    |> validate_length(:author_name, min: 1, max: 250)
  end
end
