defmodule IPA.Address do
  @moduledoc """
  Functions for defining an IP address struct from a valid IP address.

  The IP address struct contains the original dot-decimal
  notation address, it's IP version, and the address as a
  binary value, a hexadecimal value, a binary dot notation,
  and a 4 element tuple.
  """

	defstruct address: nil, version: 4, bin: nil, hex: nil, bits: nil, tuple: nil, address_type: nil, reserved: nil

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

  defp addr_to_list_of_bin(addr) do
    addr
    |> convert_addr_base(2, 8)
  end

  defp addr_to_bin(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join()
    |> add_prefix("0b")
  end

  defp addr_to_bits(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join(".")
  end

  defp addr_to_hex(addr) do
    addr
    |> convert_addr_base(16, 2)
    |> Enum.join()
    |> add_prefix("0x")
  end

  defp addr_to_tuple(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  defp convert_addr_base(addr, base, padding) do
    addr
    |> String.split(".")
    |> Stream.map(&String.to_integer(&1))
    |> Stream.map(&Integer.to_string(&1, base))
    |> Stream.map(&zero_padding(&1, padding))
  end

  defp zero_padding(n, len) when byte_size(n) == byte_size(len), do: n
  defp zero_padding(n, len), do: String.rjust(n, len, ?0)

  defp add_prefix(str, prefix), do: prefix <> str

end

