defmodule IPA.Address do
  @moduledoc """
  Functions for defining an IP address struct from a valid IP address.

  The IP address struct contains the original dot-decimal
  notation address, it's IP version, and the address as a
  binary value, a hexadecimal value, a binary dot notation,
  and a 4 element tuple.
  """

	defstruct address: nil, version: 4, bin: nil, hex: nil, bits: nil, tuple: nil

  @doc """
  Defines an IP Address struct.

  ## Example

      iex> {:ok, ip} = IPA.address("192.168.0.1")
      {:ok,
      %Address{address: "192.168.0.1",
               bin: "0b11000000101010000000000000000001",
               bits: "11000000.10101000.00000000.00000001",
               hex: "0xC0A80001",
               tuple: {192, 168, 0, 1},
               version: 4}}
      iex> ip.address
      "192.168.0.1"
      iex> ip.bin
      "0b11000000101010000000000000000001"
      iex> ip.bits
      "11000000.10101000.00000000.00000001"
      iex> ip.hex
      "0xC0A80001"
      iex> ip.tuple
      {192, 168, 0, 1}
      iex> ip.version
      4
  """
  @spec address(String.t) :: %Address{address: String.t,
                                      version: integer,
                                      bin: String.t,
                                      bits: String.t,
                                      hex: String.t,
                                      tuple: tuple}
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

  defp addr_to_bits(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join(".")
  end

  defp addr_to_bin(addr) do
    "0b" <> (addr |> addr_to_list_of_bin |> Enum.join)
  end

  defp addr_to_list_of_bin(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&dec_to_bin/1)
  end

  defp justify(n, len) when byte_size(n) == byte_size(len), do: n
  defp justify(n, len), do: String.rjust(n, len, ?0)

  defp dec_to_bin(n) when is_binary(n) do
    dec_to_bin(String.to_integer(n), "")
  end
  defp dec_to_bin(n) when is_integer(n) do
    dec_to_bin(n, "")
  end

  defp dec_to_bin(0, acc), do: justify(acc, 8)
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
  defp dec_to_hex(0, acc), do: justify(acc, 2)
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

