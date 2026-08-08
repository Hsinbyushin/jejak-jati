defmodule JejakJati.Bibliography.ISBN do
  @moduledoc """
  Normalizes and compares ISBN-10 and ISBN-13 identifiers.

  Jejak Jati may receive the same publication identifier in different forms,
  for example:

      9832085012
      9789832085010
      978-983-2085-01-0

  To make bibliographic matching reliable, ISBN-10 values are converted to
  their equivalent ISBN-13 representation before comparison.
  """

  @doc """
  Returns a normalized ISBN-13 representation when possible.

  Non-ISBN values return `nil`.
  """
  def normalize(nil), do: nil

  def normalize(value) when is_binary(value) do
    value
    |> clean()
    |> case do
      isbn when byte_size(isbn) == 13 ->
        if valid_isbn13?(isbn), do: isbn, else: nil

      isbn when byte_size(isbn) == 10 ->
        if valid_isbn10?(isbn), do: isbn10_to_isbn13(isbn), else: nil

      _ ->
        nil
    end
  end

  @doc """
  Returns true when two ISBN values identify the same publication.
  """
  def equivalent?(left, right) do
    case {normalize(left), normalize(right)} do
      {nil, _} -> false
      {_, nil} -> false
      {normalized, normalized} -> true
      _ -> false
    end
  end

  defp clean(value) do
    value
    |> String.replace(~r/[^0-9Xx]/u, "")
    |> String.upcase()
  end

  defp valid_isbn10?(isbn) do
    chars = String.graphemes(isbn)

    case chars do
      [a, b, c, d, e, f, g, h, i, check] ->
        digits =
          [a, b, c, d, e, f, g, h, i]
          |> Enum.map(&String.to_integer/1)

        check_value =
          case check do
            "X" -> 10
            digit -> String.to_integer(digit)
          end

        weighted_sum =
          digits
          |> Enum.with_index()
          |> Enum.reduce(0, fn {digit, index}, acc ->
            acc + digit * (10 - index)
          end)

        rem(weighted_sum + check_value, 11) == 0

      _ ->
        false
    end
  rescue
    ArgumentError -> false
  end

  defp valid_isbn13?(isbn) do
    digits =
      isbn
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)

    case digits do
      [d1, d2, d3, d4, d5, d6, d7, d8, d9, d10, d11, d12, check] ->
        sum =
          d1 +
            3 * d2 +
            d3 +
            3 * d4 +
            d5 +
            3 * d6 +
            d7 +
            3 * d8 +
            d9 +
            3 * d10 +
            d11 +
            3 * d12

        expected = rem(10 - rem(sum, 10), 10)

        expected == check

      _ ->
        false
    end
  rescue
    ArgumentError -> false
  end

  defp isbn10_to_isbn13(isbn10) do
    base =
      "978" <> String.slice(isbn10, 0, 9)

    check_digit =
      base
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
      |> Enum.with_index()
      |> Enum.reduce(0, fn {digit, index}, acc ->
        multiplier = if rem(index, 2) == 0, do: 1, else: 3
        acc + digit * multiplier
      end)
      |> then(fn sum ->
        rem(10 - rem(sum, 10), 10)
      end)

    base <> Integer.to_string(check_digit)
  end
end
