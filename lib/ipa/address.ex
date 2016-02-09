defmodule IPA.Address do
	defstruct address: nil, version: 4, bin: nil, hex: nil, bits: nil, tuple: nil

  def address(addr) do
    case Valid.Address.valid?(addr) do
      true -> {:ok, %Address{address: addr,
                             bin: addr_to_bin(addr),
                             bits: addr_to_bits(addr),
                             hex: addr_to_hex(addr),
                             tuple: addr_to_tuple(addr)}}
      false -> {:error, "Not a valid ip address"}
    end
  end

  def valid_octet?(octet) when octet >= 0 and octet < 256, do: true
  def valid_octet?(_), do: false

  defp addr_to_list_of_bin(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&dec_to_bin/1)
  end

  defp addr_to_bits(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join(".")
  end

  defp addr_to_bin(addr) do
    "0b" <> (addr |> addr_to_list_of_bin |> Enum.join)
  end

  defp dec_to_bin(n) when is_binary(n) do
    dec_to_bin(String.to_integer(n), "")
  end
  defp dec_to_bin(n) when is_integer(n) do
    dec_to_bin(n, "")
  end

  defp dec_to_bin(0, acc) do
    cond do
      String.length(acc) < 8 -> String.rjust(acc, 8, ?0)
      true -> acc
    end
  end
  defp dec_to_bin(n, acc) do
	  dec_to_bin(div(n, 2), to_string(rem(n, 2)) <> acc)
  end

  defp addr_to_tuple(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  defp addr_to_hex(addr) do
    hex_addr = addr
    |> String.split(".")
    |> Enum.map(&dec_to_hex/1)
    |> Enum.join()

    "0x" <> hex_addr
  end

  defp dec_to_hex(n) when is_binary(n) do
    dec_to_hex(String.to_integer(n), "")
  end
  defp dec_to_hex(n) when is_integer(n) do
    dec_to_hex(n, "")
  end
  defp dec_to_hex(0, acc)do
    cond do
      String.length(acc) < 2 -> String.rjust(acc, 2, ?0)
      true -> acc
    end
  end
  defp dec_to_hex(n, acc) do
    dec_to_hex(div(n, 16), (rem(n, 16) |> hex_notation |> to_string) <> acc)
  end

  defp hex_notation(n) when n < 10, do: n
  defp hex_notation(10), do: "A"
  defp hex_notation(11), do: "B"
  defp hex_notation(12), do: "C"
  defp hex_notation(13), do: "D"
  defp hex_notation(14), do: "E"
  defp hex_notation(15), do: "F"
end

