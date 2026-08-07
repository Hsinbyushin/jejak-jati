defmodule JejakJati.Sources.OpenLibrary do
  @moduledoc """
  Bibliographic source adapter for the Open Library Search API.

  The adapter is responsible only for querying Open Library and normalizing
  returned records into Jejak Jati `WorkResult` structs.

  Candidate ranking and confidence decisions are handled separately by the
  WorkMatcher.
  """
  @req_options Application.compile_env(
                 :jejak_jati,
                 :open_library_req_options,
                 []
               )

  @behaviour JejakJati.Sources.BibliographicSource

  alias JejakJati.Sources.WorkResult

  @base_url "https://openlibrary.org/search.json"

  @impl true
  def source_name, do: :open_library

  @impl true
  def search_work(title, author_name) do
    params =
      [
        title: title,
        fields: "key,title,author_name,isbn,first_publish_year,publisher",
        limit: 10
      ]
      |> maybe_add_author(author_name)

    request_options =
      [
        params: params,
        headers: [
          {"user-agent", "JejakJati/0.1"}
        ]
      ] ++ @req_options

    case Req.get(@base_url, request_options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, parse_results(body)}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_add_author(params, nil), do: params
  defp maybe_add_author(params, ""), do: params

  defp maybe_add_author(params, author_name) do
    Keyword.put(params, :author, author_name)
  end

  defp parse_results(%{"docs" => docs}) when is_list(docs) do
    Enum.map(docs, &parse_result/1)
  end

  defp parse_results(_), do: []

  defp parse_result(doc) do
    key = doc["key"]

    %WorkResult{
      source: :open_library,
      source_id: normalize_key(key),
      title: doc["title"],
      author_name: first(doc["author_name"]),
      isbn: first(doc["isbn"]),
      publication_year: stringify(doc["first_publish_year"]),
      publisher: first(doc["publisher"]),
      source_url: source_url(key)
    }
  end

  defp first([value | _]), do: value
  defp first(_), do: nil

  defp stringify(nil), do: nil
  defp stringify(value), do: to_string(value)

  defp normalize_key(nil), do: nil
  defp normalize_key("/works/" <> id), do: id
  defp normalize_key(key), do: key

  defp source_url(nil), do: nil
  defp source_url(key), do: "https://openlibrary.org#{key}"
end
