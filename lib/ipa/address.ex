defmodule IPA.Address do
  @moduledoc """
  Functions for defining an IP address struct from a valid IP address.

  The IP address struct contains the original dot-decimal
  notation address, it's IP version, and the address as a
  binary value, a hexadecimal value, a binary dot notation,
  and a 4 element tuple.
  """

  @typedoc """
  The IP Address Struct
  """
  @type addr_struct :: %IPA.Address{address: String.t,
                             version: non_neg_integer,
                             bin: String.t,
                             bits: String.t,
                             hex: String.t,
                             octets: tuple,
                             block: atom}


  defstruct [
    address: nil,
    version: 4,
    bin: nil,
    hex: nil,
    bits: nil,
    octets: nil,
    block: nil,
  ]

  @addr_regex ~r/^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/

  @doc """
  Defines an IP Address struct.

  ## Example

      iex> {:ok, ip} = IPA.address("192.168.0.1")
      {:ok,
      %IPA.Address{address: "192.168.0.1", address_type: nil,
      bin: "0b11000000101010000000000000000001",
      bits: "11000000.10101000.00000000.00000001", block: :rfc1918,
      hex: "0xC0A80001", octets: {192, 168, 0, 1}, version: 4}}
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
      iex> ip.octets
      {192, 168, 0, 1}
      iex> ip.version
      4
      iex> IPA.address("192.168.0.256")
      {:error, "Not a valid ip address"}
      iex> IPA.address("192.168.0")
      {:error, "Not a valid ip address"}

  """
  @spec address(String.t) :: addr_struct | :invalid
  def address(addr) do
    cond do
      valid?(addr) ->
        bin_worker = Task.async(__MODULE__, :addr_to_bin, [addr])
        bits_worker = Task.async(__MODULE__, :addr_to_bits, [addr])
        hex_worker = Task.async(__MODULE__, :addr_to_hex, [addr])
        octets_worker = Task.async(__MODULE__, :addr_to_octets, [addr])
        block_worker = Task.async(__MODULE__, :block, [addr])

        addr = %IPA.Address{
          address: addr,
          bin: Task.await(bin_worker),
          bits: Task.await(bits_worker),
          hex: Task.await(hex_worker),
          octets: Task.await(octets_worker),
          block: Task.await(block_worker)}

        {:ok, addr}
      true ->
        {:error, :invalid_ipv4_address}
    end
  end

  def valid?(addr), do: Regex.match?(@addr_regex, addr)

  # Convert the address from decimal to a "0b" prefixed binary number
  def to_binary(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join()
    |> add_prefix("0b")
  end

  # Convert address from decimal to binary bits
  def to_bits(addr) do
    addr
    |> addr_to_list_of_bin
    |> Enum.join(".")
  end

  # Convert address from decimal to hexadecimal
  def to_hex(addr) do
    addr
    |> convert_addr_base(16, 2)
    |> Enum.join()
    |> add_prefix("0x")
  end

  # Convert address string to 4 element tuple
  def to_octets(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  # Convert the address to a list of 4 binary numbers
  # for use in `to_binary` & `to_bits`
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
    |> Stream.map(&zero_pad(&1, max_length))
  end

  # When numbers are converted from decimal to binary/hex
  # any leading zeroes are discarded, so we need to zero-pad
  # them to their expected length (ie. 8 for binary, 2 for hex)
  defp zero_pad(n, max_length) when byte_size(n) == byte_size(max_length), do: n
  defp zero_pad(n, max_length), do: String.rjust(n, max_length, ?0)

  # Add numerical prefix (ie. "0b" for binary, "0x" for hex)
  defp add_prefix(str, prefix), do: prefix <> str

  def block(addr) do
    addr
    |> to_octets
    |> which_block?
  end

  defp which_block?({0, _, _, _}),                                      do: :this_network
  defp which_block?({10, _, _, _}),                                     do: :rfc1918
  defp which_block?({100, b, _, _}) when b > 63 and b < 128,            do: :rfc6598
  defp which_block?({127, _, _, _}),                                    do: :loopback
  defp which_block?({169, 254, _, _}),                                  do: :link_local
  defp which_block?({172, b, _, _}) when b > 15 and b < 32,             do: :rfc1918
  defp which_block?({192, 0, 0, _}),                                    do: :rfc5736
  defp which_block?({192, 0, 2, 0}),                                    do: :rfc5737
  defp which_block?({192, 88, 99, _}),                                  do: :rfc3068
  defp which_block?({192, 168, _, _}),                                  do: :rfc1918
  defp which_block?({198, b, _, _}) when b > 17 and b < 20,             do: :rfc2544
  defp which_block?({198, 51, 100, _}),                                 do: :rfc5737
  defp which_block?({203, 0, 113, _}),                                  do: :rfc5737
  defp which_block?({a, _, _, _}) when a > 223 and a < 240,             do: :multicast
  defp which_block?({a, _, _, d}) when a > 239 and a < 256 and d < 255, do: :future
  defp which_block?({255, 255, 255, 255}),                              do: :limited_broadcast
  defp which_block?(_),                                                 do: :public
end
