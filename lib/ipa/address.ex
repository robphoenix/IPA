defmodule IPA.Address do
  @moduledoc """
  Functions for working with IP addresses.

  Currently only compatible with IPv4 addresses.
  """

  @type addr :: String.t

  @type addr_struct :: %IPA.Address{
    address: addr,
    version: non_neg_integer,
    binary: String.t,
    bits: String.t,
    hex: String.t,
    octets: tuple,
    block: atom,
    reserved: boolean}

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
  Defines an IP Address struct containing:

   * `address` - original dotted-decimal notation address
   * `version` - IP version
   * `reserved` - whether it is a reserved address or not
   * `block` - it's address block, either public or one of a number of private blocks
   * `binary` - the address as a binary value
   * `hex` - the address as a hexadecimal value
   * `bits` - the address as binary dot notation
   * `octets` - the address as a 4 element tuple.

  Returns `{:ok, ip}`, where ip is the struct defined above,
  or `{:error, :invalid_ipv4_address}` if the IP address is invalid.

  ## Examples

      iex> {:ok, ip} = IPA.address("192.168.0.1")
      {:ok,
      %IPA.Address{address: "192.168.0.1",
      binary: "0b11000000101010000000000000000001",
      bits: "11000000.10101000.00000000.00000001",
      block: :rfc1918,
      hex: "0xC0A80001",
      octets: {192, 168, 0, 1},
      reserved: true,
      version: 4}}
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
  @spec address(addr) :: {:ok, addr_struct} | {:error, atom}
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
  Same as `address/1` but raises `IPError` if it fails, returns the IP Address struct otherwise.
  """
  @spec address!(addr) :: addr_struct | no_return
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
  @spec valid?(addr) :: boolean
  def valid?(addr), do: Regex.match?(@addr_regex, addr)

  @doc """
  Converts a dot decimal IP address to a `0b` prefixed binary number.

  ## Example

      iex> IPA.Address.to_binary("192.168.0.1")
      "0b11000000101010000000000000000001"
  """
  @spec to_binary(addr) :: String.t
  def to_binary(addr) do
    addr
    |> convert_addr_base(2, 8)
    |> Enum.join()
    |> add_prefix("0b")
  end

  @doc """
  Converts a dot decimal IP address to binary bits.

  ## Example

      iex> IPA.Address.to_bits("192.168.0.1")
      "11000000.10101000.00000000.00000001"
  """
  @spec to_bits(addr) :: String.t
  def to_bits(addr) do
    addr
    |> convert_addr_base(2, 8)
    |> Enum.join(".")
  end

  @doc """
  Converts a dot decimal IP address to a `0x` prefixed hexadecimal
  number.

  ## Example

      iex> IPA.Address.to_hex("192.168.0.1")
      "0xC0A80001"
  """
  @spec to_hex(addr) :: String.t
  def to_hex(addr) do
    addr
    |> convert_addr_base(16, 2)
    |> Enum.join()
    |> add_prefix("0x")
  end

  @doc """
  Converst a dot decimal IP address to a 4 element tuple,
  representing the given addresses 4 octets.

  ## Example

      iex> IPA.Address.to_octets("192.168.0.1")
      {192, 168, 0, 1}
  """
  @spec to_octets(addr) :: {integer}
  def to_octets(addr) do
    addr
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  @doc """
  Checks whether a given IP address is reserved.
  """
  @spec reserved?(addr) :: boolean
  def reserved?(addr) do
    case block(addr) do
      :public -> false
      _ -> true
    end
  end

  @doc """
  Returns an atom describing which reserved block the address is a member of if it is a private address, returns `:public` otherwise.

  [Available blocks](https://en.wikipedia.org/wiki/Reserved_IP_addresses):

  * `:this_network` - `0.0.0.0/8` Used for broadcast messages to the current "this" network as specified by RFC 1700, page 4.
  * `:rfc1918` - `10.0.0.0/8`, `172.16.0.0/12` & `192.168.0.0/16` Used for local communications within a private network as specified by RFC 1918.
  * `:rfc6598` - `100.64.0.0/10` Used for communications between a service provider and its subscribers when using a Carrier-grade NAT, as specified by RFC 6598.
  * `:loopback` - `127.0.0.0/8` Used for loopback addresses to the local host, as specified by RFC 990.
  * `:link_local` - `169.254.0.0/16` Used for link-local addresses between two hosts on a single link when no IP address is otherwise specified, such as would have normally been retrieved from a DHCP server, as specified by RFC 3927.
  * `:rfc5736` - `192.0.0.0/24` Used for the IANA IPv4 Special Purpose Address Registry as specified by RFC 5736.
  * `:rfc5737` - `192.0.2.0/24`, `198.51.100.0/24` & `203.0.113.0/24` Assigned as "TEST-NET" in RFC 5737 for use solely in documentation and example source code and should not be used publicly.
  * `:rfc3068` - `192.88.99.0/24` Used by 6to4 anycast relays as specified by RFC 3068.
  * `:rfc2544` - `198.18.0.0/15` Used for testing of inter-network communications between two separate subnets as specified in RFC 2544.
  * `:multicast` - `224.0.0.0/4` Reserved for multicast assignments as specified in RFC 5771. `233.252.0.0/24` is assigned as "MCAST-TEST-NET" for use solely in documentation and example source code.
  * `:future` - `240.0.0.0/4` Reserved for future use, as specified by RFC 6890.
  * `:limited_broadcast` - `255.255.255.255/32` Reserved for the "limited broadcast" destination address, as specified by RFC 6890.
  * `:public` - All other addresses are public.

  ## Examples

  iex> IPA.Address.block("8.8.8.8")
  :public
  iex> IPA.Address.block("192.168.0.1")
  :rfc1918
  """
  @spec block(addr) :: atom
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
