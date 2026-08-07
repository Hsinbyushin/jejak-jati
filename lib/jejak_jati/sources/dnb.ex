defmodule JejakJati.Sources.DNB do
  @moduledoc """
  Source adapter for bibliographic searches against the SRU interface of the
  Deutsche Nationalbibliothek (DNB).

  The adapter isolates all DNB-specific concerns from the rest of Jejak Jati.

  Its responsibilities are:

    * building DNB-specific CQL queries,
    * sending requests to the DNB SRU service,
    * parsing MARC21 XML responses,
    * normalizing DNB records into Jejak Jati's `WorkResult` structure.

  The adapter deliberately performs no database writes. It only communicates
  with the external source and returns normalized results.

  This separation allows the research pipeline to work with bibliographic
  results without having to understand SRU, CQL, MARC21, or DNB-specific
  conventions.
  """
  @behaviour JejakJati.Sources.BibliographicSource

  import SweetXml

  alias JejakJati.Sources.WorkResult

  @base_url "https://services.dnb.de/sru/dnb"

  # Common words aren't particularly useful when we have to fall back to a
  # word-based title search. Removing them reduces the number of unrelated
  # records returned for titles such as "In Search of Modernity".
  #
  # This is intentionally small for now. It isn't intended to be a general
  # linguistic stop-word implementation.

  @req_options Application.compile_env(
                 :jejak_jati,
                 :dnb_req_options,
                 []
               )

  @title_stopwords ~w(
    a
    an
    and
    der
    die
    das
    ein
    eine
    for
    in
    of
    on
    the
    to
    und
    von
  )

  @impl true
  def source_name, do: :dnb

  @doc """
  Searches the DNB catalogue for a bibliographic work.

  The function returns normalized `WorkResult` structs rather than exposing
  MARC21 records to callers.

  A successful request always returns `{:ok, results}`. An empty list means
  that the request itself succeeded but no matching records were found.

  HTTP or protocol failures are returned as `{:error, reason}`.
  """

  @impl true

  def search_work(title, author_name) do
    query = build_query(title, author_name)

    case Req.get(
           @base_url,
           [
             params: [
               version: "1.1",
               operation: "searchRetrieve",
               query: query,
               recordSchema: "MARC21-xml",
               maximumRecords: "10"
             ],
             receive_timeout: 10_000
           ] ++ @req_options
         ) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        parse_response(body)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:unexpected_status, status}}

      {:error, exception} ->
        {:error, {:request_failed, exception}}
    end
  end

  # Build a reasonably broad title query for candidate discovery.
  #
  # At this stage we deliberately don't require the author name. Our previous
  # experiment showed that combining title and person too strictly can result
  # in zero candidates even when useful bibliographic records exist.
  #
  # Instead, this query retrieves candidates based on significant title words.
  # Author matching will later become part of Jejak Jati's candidate ranking.
  defp build_query(title, _author_name) do
    title
    |> significant_title_words()
    |> Enum.map_join(" and ", fn word ->
      ~s(tit="#{escape_cql(word)}")
    end)
  end

  # Split a title into individual search terms and remove common stop words.
  #
  # For example:
  #
  #     "In Search of Modernity"
  #
  # becomes:
  #
  #     ["Search", "Modernity"]
  #
  # This is considerably more useful than asking the catalogue to search for
  # generic terms such as "in" or "of".
  defp significant_title_words(title) do
    words =
      title
      |> String.split(~r/\s+/u, trim: true)
      |> Enum.reject(fn word ->
        String.downcase(word) in @title_stopwords
      end)

    # Don't accidentally produce an empty CQL query for a title consisting
    # entirely of stop words. In that unusual case, fall back to the original
    # title words.
    case words do
      [] -> String.split(title, ~r/\s+/u, trim: true)
      words -> words
    end
  end

  # Escape characters that have special meaning inside a quoted CQL term.
  defp escape_cql(value) do
    value
    |> String.replace("\\", "\\\\")
    |> String.replace("\"", "\\\"")
  end

  # Parse the SRU response and extract the embedded MARC21 records.
  #
  # We intentionally extract potentially repeatable MARC fields as lists.
  # MARC21 permits fields such as ISBN (020) and publication information (264)
  # to occur more than once.
  #
  # Using SweetXml's scalar string modifier (`s`) on multiple matching nodes
  # can concatenate their contents. That caused values such as:
  #
  #     "20142014"
  #
  # or:
  #
  #     "97813493177071349317705"
  #
  # Reading them as lists lets us make the choice explicitly.
  defp parse_response(xml) do
    records =
      xpath(
        xml,
        ~x"//*[local-name()='recordData']/*[local-name()='record']"l,
        source_id: ~x"./*[local-name()='controlfield'][@tag='001']/text()"s,
        titles:
          ~x"./*[local-name()='datafield'][@tag='245']/*[local-name()='subfield'][@code='a']/text()"ls,
        authors:
          ~x"./*[local-name()='datafield'][@tag='100']/*[local-name()='subfield'][@code='a']/text()"ls,
        isbns:
          ~x"./*[local-name()='datafield'][@tag='020']/*[local-name()='subfield'][@code='a']/text()"ls,
        publication_years:
          ~x"./*[local-name()='datafield'][@tag='264']/*[local-name()='subfield'][@code='c']/text()"ls,
        publishers:
          ~x"./*[local-name()='datafield'][@tag='264']/*[local-name()='subfield'][@code='b']/text()"ls
      )

    results =
      records
      |> Enum.map(&normalize_record/1)
      |> Enum.reject(&is_nil(&1.source_id))
      |> Enum.reject(&is_nil(&1.title))

    {:ok, results}
  end

  # Translate a DNB/MARC21 record into Jejak Jati's source-independent
  # bibliographic result structure.
  #
  # The rest of the application should only need to understand WorkResult,
  # never the MARC fields from which it originated.
  defp normalize_record(record) do
    source_id = blank_to_nil(record.source_id)

    %WorkResult{
      source: :dnb,
      source_id: source_id,
      title:
        record.titles
        |> first_non_blank()
        |> clean_title(),
      author_name:
        record.authors
        |> first_non_blank()
        |> clean_text(),
      isbn:
        record.isbns
        |> first_non_blank()
        |> clean_isbn(),
      publication_year:
        record.publication_years
        |> first_non_blank()
        |> clean_publication_year(),
      publisher:
        record.publishers
        |> first_non_blank()
        |> clean_text(),
      source_url: source_url(source_id)
    }
  end

  # Return the first non-empty value from a repeatable MARC field.
  #
  # We deliberately keep this policy simple for the first adapter version.
  # Later we may preserve all source values as Evidence rather than selecting
  # only one.
  defp first_non_blank(values) when is_list(values) do
    values
    |> Enum.map(&blank_to_nil/1)
    |> Enum.find(&(!is_nil(&1)))
  end

  defp first_non_blank(_), do: nil

  # Normalize general textual MARC values.
  defp clean_text(nil), do: nil

  defp clean_text(value) do
    value
    |> normalize_dnb_text()
    |> blank_to_nil()
  end

  # MARC 245$a often ends with cataloguing punctuation such as "/" because
  # additional responsibility information follows in another subfield.
  #
  # We don't want that punctuation to become part of our normalized title.
  defp clean_title(nil), do: nil

  defp clean_title(value) do
    value
    |> normalize_dnb_text()
    |> String.trim_trailing("/")
    |> String.trim()
    |> blank_to_nil()
  end

  # ISBN fields may contain explanatory text after the identifier. For the
  # first implementation we extract the first ISBN-looking sequence.
  #
  # This accepts both ISBN-10 and ISBN-13 and tolerates hyphens.
  defp clean_isbn(nil), do: nil

  defp clean_isbn(value) do
    case Regex.run(~r/\b(?:97[89][\d-]{10,}|[\d][\dXx-]{8,})\b/u, value) do
      [isbn | _] ->
        isbn
        |> String.replace("-", "")
        |> blank_to_nil()

      nil ->
        blank_to_nil(value)
    end
  end

  # Publication statements aren't always plain years. Extracting a four-digit
  # year gives us a predictable value for later candidate comparison while
  # still leaving room to preserve the raw statement as Evidence in a future
  # iteration.
  defp clean_publication_year(nil), do: nil

  defp clean_publication_year(value) do
    case Regex.run(~r/\b(?:1[5-9]\d{2}|20\d{2}|21\d{2})\b/u, value) do
      [year | _] -> year
      nil -> blank_to_nil(value)
    end
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      value -> value
    end
  end

  defp blank_to_nil(value), do: value

  # DNB record identifiers can be resolved through d-nb.info. Keeping the
  # source URL alongside the normalized result will later allow Jejak Jati to
  # show users exactly where a claim or candidate originated.
  defp source_url(nil), do: nil

  defp source_url(id) do
    "https://d-nb.info/#{String.trim(id)}"
  end

  defp normalize_dnb_text(value) do
    value
    |> String.replace("\u0098", "")
    |> String.replace("\u009C", "")
    |> String.trim()
  end
end
