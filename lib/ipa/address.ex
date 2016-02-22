defmodule IPA.Address do
  @moduledoc """
  Functions for defining an IP address struct from a valid IP address.

  The IP address struct contains the original dot-decimal
  notation address, it's IP version, and the address as a
  binary value, a hexadecimal value, a binary dot notation,
  and a 4 element tuple.
  """

  defstruct [
    address: nil,
    version: 4,
    bin: nil,
    hex: nil,
    bits: nil,
    tuple: nil,
    block: nil,
  ]

  @doc """
  Defines an IP Address struct.

  ## Example

      iex> {:ok, ip} = IPA.address("192.168.0.1")
      {:ok,
      %IPA.Address{address: "192.168.0.1", address_type: nil,
      bin: "0b11000000101010000000000000000001",
      bits: "11000000.10101000.00000000.00000001", block: :rfc1918,
      hex: "0xC0A80001", tuple: {192, 168, 0, 1}, version: 4}}
      iex> ip.address
      "192.168.0.1"
      iex> ip.bin
      "0b11000000101010000000000000000001"
      iex> ip.bits
      "11000000.10101000.00000000.00000001"
      iex> ip.block
      :rfc1918
      iex> ip.hex
      "0xC0A80001"
      iex> ip.tuple
      {192, 168, 0, 1}
      iex> ip.version
      4
      iex> IPA.address("192.168.0.256")
      {:error, "Not a valid ip address"}
      iex> IPA.address("192.168.0")
      {:error, "Not a valid ip address"}

  """
  @spec address(String.t) :: {atom, %IPA.Address{
                                 address: String.t,
                                 version: non_neg_integer,
                                 bin: String.t,
                                 bits: String.t,
                                 hex: String.t,
                                 tuple: tuple,
                                 block: atom}} | {atom, String.t}
  def address(addr) do
    if valid?(addr) do
      bin_worker = Task.async(fn -> addr_to_bin(addr) end)
      bits_worker = Task.async(fn -> addr_to_bits(addr) end)
      hex_worker = Task.async(fn -> addr_to_hex(addr) end)
      tuple_worker = Task.async(fn -> addr_to_tuple(addr) end)
      block_worker = Task.async(fn -> block(addr) end)
      {:ok, %IPA.Address{
          address: addr,
          bin: Task.await(bin_worker),
          bits: Task.await(bits_worker),
          hex: Task.await(hex_worker),
          tuple: Task.await(tuple_worker),
          block: Task.await(block_worker)}}
    else
      {:error, "Not a valid IP address"}
    end
  end

  def valid?(addr) do
    cond do
      String.ends_with?(addr, ".") ->
        :false
      true ->
        addr
        |> String.split(".", trim: true)
        |> number_of_octets
    end
  end

  defp number_of_octets(octets) when length(octets) == 4 do
    octets
    |> Enum.map(&String.to_integer/1)
    |> Enum.all?(&valid_octet?/1)
  end
  defp number_of_octets(_octets), do: :false

  defp valid_octet?(octet) when octet in 0..255, do: true
  defp valid_octet?(_), do: false

  # Convert the address from decimal to a "0b" prefixed binary number
  def addr_to_bin(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join()
    |> add_prefix("0b")
  end

  # Convert address from decimal to binary bits
  def addr_to_bits(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join(".")
  end

  # Convert address from decimal to hexadecimal
  def addr_to_hex(addr) do
    addr
    |> convert_addr_base(16, 2)
    |> Enum.join()
    |> add_prefix("0x")
  end

  # Convert address string to 4 element tuple
  def addr_to_tuple(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  # Convert the address to a list of 4 binary numbers
  # for use in `addr_to_bin` & `addr_to_bits`
  defp addr_to_list_of_bin(addr) do
    addr
    |> convert_addr_base(2, 8)
  end

  # Convert address to different numerical base, (ie. 2 for binary, 16 for hex),
  # and then appropriately zero-pad the number
  defp convert_addr_base(addr, base, max_length) do
    addr
    |> String.split(".")
    |> Stream.map(&String.to_integer(&1))
    |> Stream.map(&Integer.to_string(&1, base))
    |> Stream.map(&zero_padding(&1, max_length))
  end

  # When numbers are converted from decimal to binary/hex
  # any leading zeroes are discarded, so we need to zero-pad
  # them to their expected length (ie. 8 for binary, 2 for hex)
  defp zero_padding(n, max_length) when byte_size(n) == byte_size(max_length), do: n
  defp zero_padding(n, max_length), do: String.rjust(n, max_length, ?0)

  # Add numerical prefix (ie. "0b" for binary, "0x" for hex)
  defp add_prefix(str, prefix), do: prefix <> str

  defp block(addr) do
    addr
    |> addr_to_tuple
    |> _block
  end

  defp _block({0, _, _, _}),                                      do: :this_network
  defp _block({10, _, _, _}),                                     do: :rfc1918
  defp _block({100, b, _, _}) when b > 63 and b < 128,            do: :rfc6598
  defp _block({127, _, _, _}),                                    do: :loopback
  defp _block({169, 254, _, _}),                                  do: :link_local
  defp _block({172, b, _, _}) when b > 15 and b < 32,             do: :rfc1918
  defp _block({192, 0, 0, _}),                                    do: :rfc5736
  defp _block({192, 0, 2, 0}),                                    do: :rfc5737
  defp _block({192, 88, 99, _}),                                  do: :rfc3068
  defp _block({192, 168, _, _}),                                  do: :rfc1918
  defp _block({198, b, _, _}) when b > 17 and b < 20,             do: :rfc2544
  defp _block({198, 51, 100, _}),                                 do: :rfc5737
  defp _block({203, 0, 113, _}),                                  do: :rfc5737
  defp _block({a, _, _, _}) when a > 223 and a < 240,             do: :multicast
  defp _block({a, _, _, d}) when a > 239 and a < 256 and d < 255, do: :future
  defp _block({255, 255, 255, 255}),                              do: :limited_broadcast
  defp _block(_),                                                 do: :public
end
