defmodule JejakJati.Sources.WorkResult do
  @moduledoc """
  Normalized bibliographic result returned by a source adapter.

  Source adapters translate source-specific responses into this structure so
  that the rest of Jejak Jati doesn't need to understand DNB MARCXML,
  Wikidata JSON, or any other external representation.
  """

  @enforce_keys [:source, :source_id, :title]

  @type t :: %__MODULE__{
          source: atom(),
          source_id: String.t(),
          title: String.t(),
          author_name: String.t() | nil,
          isbn: String.t() | nil,
          publication_year: String.t() | nil,
          publisher: String.t() | nil,
          source_url: String.t() | nil
        }

  defstruct [
    :source,
    :source_id,
    :title,
    :author_name,
    :isbn,
    :publication_year,
    :publisher,
    :source_url
  ]
end
