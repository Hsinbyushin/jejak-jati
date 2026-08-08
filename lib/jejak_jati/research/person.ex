defmodule JejakJati.Research.Person do
  @moduledoc """
  Represents a person investigated by Jejak Jati.

  A person is the central entity around which bibliographic research,
  authority records, and later evidence and claims can be organized.

  The schema deliberately contains only a small set of descriptive fields.
  Source-specific identifiers such as GND, VIAF, or Library of Congress
  identifiers belong in separate authority records rather than directly
  on the person.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias JejakJati.Research.ResearchRun

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "people" do
    field :preferred_name, :string
    field :birth_year, :integer
    field :death_year, :integer

    has_many :research_runs, ResearchRun

    timestamps(type: :utc_datetime)
  end

  def changeset(person, attrs) do
    person
    |> cast(attrs, [
      :preferred_name,
      :birth_year,
      :death_year
    ])
    |> validate_required([:preferred_name])
    |> validate_length(:preferred_name, min: 1, max: 255)
    |> validate_year(:birth_year)
    |> validate_year(:death_year)
    |> validate_year_order()
  end

  defp validate_year(changeset, field) do
    validate_number(
      changeset,
      field,
      greater_than: 0,
      less_than: 10_000
    )
  end

  defp validate_year_order(changeset) do
    birth_year = get_field(changeset, :birth_year)
    death_year = get_field(changeset, :death_year)

    if birth_year && death_year && death_year < birth_year do
      add_error(
        changeset,
        :death_year,
        "must not be earlier than birth year"
      )
    else
      changeset
    end
  end
end
