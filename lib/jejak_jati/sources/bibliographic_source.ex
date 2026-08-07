defmodule JejakJati.Sources.BibliographicSource do
  @moduledoc """
  Defines the common interface for bibliographic source adapters.

  A bibliographic source adapter is responsible for querying one external
  catalogue or service and normalizing its results into `WorkResult` structs.

  Source adapters should contain source-specific concerns such as:

    * request construction,
    * query syntax,
    * HTTP communication,
    * response parsing,
    * source-specific normalization.

  They should not decide whether a candidate is a reliable match. Candidate
  ranking and confidence classification belong to the WorkMatcher.
  """

  alias JejakJati.Sources.WorkResult

  @type search_result ::
          {:ok, [WorkResult.t()]}
          | {:error, term()}

  @doc """
  Searches the external source for a bibliographic work.

  A successful request returns `{:ok, results}`.

  An empty result list is a successful search with no candidates and must not
  be treated as a technical failure.
  """
  @callback search_work(
              title :: String.t(),
              author_name :: String.t() | nil
            ) :: search_result()

  @doc """
  Returns the stable identifier used for this source inside Jejak Jati.

  Examples might include `:dnb`, `:open_library`, or `:wikidata`.
  """
  @callback source_name() :: atom()
end
