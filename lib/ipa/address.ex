defmodule IPA.Address do
  @moduledoc """
  Functions for working with IP addresses.

  Currently only compatible with IPv4 addresses.
  """

  defstruct [
    address: nil,
    version: 4,
    binary: nil,
    hex: nil,
    bits: nil,
    octets: nil,
    block: nil,
    reserved: nil
  ]

  @addr_regex ~r/^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5]\
  )\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/

  @doc """
  Defines an IP Address struct which contains the original
  dot-decimal notation address, it's IP version, whether it
  is a reserved address or not, and which block of reserved
  addresses it is a part of if it is a private address, and
  the address as a binary value, a hexadecimal value, a binary
  dot notation, and a 4 element tuple.

  Returns {:ok, ip}, where ip is a struct, defined above,
  or {:error, :invalid_ipv4_address} if the IP address is invalid.

  ## Example

      iex> {:ok, ip} = IPA.address("192.168.0.1")
      {:ok,
      %IPA.Address{address: "192.168.0.1", binary: "0b11000000101010000000000000000001",
      bits: "11000000.10101000.00000000.00000001", block: :rfc1918, hex: "0xC0A80001", octets: {192, 168, 0, 1},
      reserved: true, version: 4}}
      iex> ip.address
      "192.168.0.1"
      iex> ip.binary
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
      iex> ip.reserved
      true
      iex> IPA.address("192.168.0.256")
      {:error, :invalid_ipv4_address}
      iex> IPA.address("192.168.0")
      {:error, :invalid_ipv4_address}

  """
  @spec address(String.t) ::
    {:ok, %IPA.Address{
      address: String.t,
      version: non_neg_integer,
      binary: String.t,
      bits: String.t,
      hex: String.t,
      octets: tuple,
      block: atom,
      reserved: boolean}} |
    {:error, atom}
  def address(addr) do
    if valid?(addr) do
        binary_worker = Task.async(__MODULE__, :to_binary, [addr])
        bits_worker = Task.async(__MODULE__, :to_bits, [addr])
        hex_worker = Task.async(__MODULE__, :to_hex, [addr])
        octets_worker = Task.async(__MODULE__, :to_octets, [addr])
        block_worker = Task.async(__MODULE__, :block, [addr])
        reserved_worker = Task.async(__MODULE__, :reserved?, [addr])

        addr = %IPA.Address{
          address: addr,
          binary: Task.await(binary_worker),
          bits: Task.await(bits_worker),
          hex: Task.await(hex_worker),
          octets: Task.await(octets_worker),
          block: Task.await(block_worker),
          reserved: Task.await(reserved_worker)}

        {:ok, addr}
      else
        {:error, :invalid_ipv4_address}
    end
  end

  @doc """
  Returns an IP Address struct which contains the original
  dot-decimal notation address, it's IP version, whether it
  is a reserved address or not, and which block of reserved
  addresses it is a part of if it is a private address, and
  the address as a binary value, a hexadecimal value, a binary
  dot notation, and a 4 element tuple, or raises `IPError`
  if an error occurs.
  """
  @spec address!(String.t) ::
    %IPA.Address{
      address: String.t,
      version: non_neg_integer,
      binary: String.t,
      bits: String.t,
      hex: String.t,
      octets: tuple,
      block: atom,
      reserved: boolean} |
    no_return
  def address!(addr) do
    case address(addr) do
      {:ok, ip} ->
        ip
      {:error, :invalid_ipv4_address} ->
        raise IPError, message: "Invalid IPv4 address"
    end
  end

  @doc """
  Checks if the given address is a valid IP address.

  Uses a regular expression to check there is exactly
  4 integers between 0 & 255, inclusive, separated by dots.
  Taken from [here](http://www.regular-expressions.info/numericranges.html).
  Therefore does not currently take into consideration
  the fact that `127.1` can be considered a valid IP address
  that translates to `127.0.0.1`.
  """
  @spec valid?(String.t) :: boolean
  def valid?(addr), do: Regex.match?(@addr_regex, addr)

  @doc """
  Convert a dot decimal IP address to a "0b" prefixed binary number.

  ## Example

      iex> IPA.Address.to_binary("192.168.0.1")
      "0b11000000101010000000000000000001"
  """
  @spec to_binary(String.t) :: String.t
  def to_binary(addr) do
    addr
    |> convert_addr_base(2, 8)
    |> Enum.join()
    |> add_prefix("0b")
  end

  @doc """
  Convert a dot decimal IP address to binary bits.

  ## Example

      iex> IPA.Address.to_bits("192.168.0.1")
      "11000000.10101000.00000000.00000001"
  """
  @spec to_bits(String.t) :: String.t
  def to_bits(addr) do
    addr
    |> convert_addr_base(2, 8)
    |> Enum.join(".")
  end

  @doc """
  Convert a dot decimal IP address to a "0x" prefixed hexadecimal
  number.

  ## Example

      iex> IPA.Address.to_hex("192.168.0.1")
      "0xC0A80001"
  """
  @spec to_hex(String.t) :: String.t
  def to_hex(addr) do
    addr
    |> convert_addr_base(16, 2)
    |> Enum.join()
    |> add_prefix("0x")
  end

  @doc """
  Convert a dot decimal IP address to a 4 element tuple,
  representing the given addresses 4 octets.

  ## Example

      iex> IPA.Address.to_octets("192.168.0.1")
      {192, 168, 0, 1}
  """
  @spec to_octets(String.t) :: {integer}
  def to_octets(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  @doc """
  Checks whether a given IP address is reserved.
  """
  @spec reserved?(String.t) :: boolean
  def reserved?(addr) do
    case block(addr) do
      :public -> false
      _ -> true
    end
  end

  @doc """
  Defines which block of reserved addresses the given
  address is a member of, or that it is a public address.

  ## Examples

      iex> IPA.Address.block("8.8.8.8")
      :public
      iex> IPA.Address.block("192.168.0.1")
      :rfc1918
      """
  @spec block(String.t) :: atom
  def block(addr) do
    addr
    |> to_octets
    |> which_block?
  end

  # Convert address to different numerical base,
  # (ie. 2 for binary, 16 for hex),
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
  defp zero_pad(n, max_len) when byte_size(n) == byte_size(max_len), do: n
  defp zero_pad(n, max_len), do: String.rjust(n, max_len, ?0)

  # Add numerical prefix (ie. "0b" for binary, "0x" for hex)
  defp add_prefix(str, prefix), do: prefix <> str

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
