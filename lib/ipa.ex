defmodule IPA do
  @moduledoc """
  Functions for working with IP addresses.

  Currently only compatible with IPv4 addresses.
  """

  @type addr :: String.t

  @addr_regex ~r/^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/


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

      iex> IPA.to_binary("192.168.0.1")
      "0b11000000101010000000000000000001"
  """
  @spec to_binary(addr) :: String.t
  def to_binary(addr) do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(2, 8, "", "0b")
  end

  @doc """
  Converts a dot decimal IP address to binary bits.

  ## Example

      iex> IPA.to_bits("192.168.0.1")
      "11000000.10101000.00000000.00000001"
  """
  @spec to_bits(addr) :: String.t
  def to_bits(addr) do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(2, 8, ".", "")
  end

  @doc """
  Converts a dot decimal IP address to a `0x` prefixed hexadecimal
  number.

  ## Example

      iex> IPA.to_hex("192.168.0.1")
      "0xC0A80001"
  """
  @spec to_hex(addr) :: String.t
  def to_hex(addr) do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(16, 2, "", "0x")
  end

  @doc """
  Converst a dot decimal IP address to a 4 element tuple,
  representing the given addresses 4 octets.

  ## Example

      iex> IPA.to_octets("192.168.0.1")
      {192, 168, 0, 1}
  """
  @spec to_octets(addr) :: {integer}
  def to_octets(addr) do
    addr
    |> validate_and_transform_to_int_list
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

  iex> IPA.block("8.8.8.8")
  :public
  iex> IPA.block("192.168.0.1")
  :rfc1918
  """
  @spec block(addr) :: atom
  def block(addr) do
    addr
    |> to_octets
    |> which_block?
  end

  # check if address is valid, and if it is transform
  # it into a list of integers.
  defp validate_and_transform_to_int_list(addr) do
    if valid?(addr) do
      for n <- String.split(addr, "."), do: String.to_integer(n)
    else
      raise IPError
    end
  end

  # Convert address to different numerical base,
  # (ie. 2 for binary, 16 for hex), zero-pads
  # joins and adds a prefix
  defp transform_addr(addr, base, max_length, joiner, prefix) do
    addr
    |> Stream.map(&Integer.to_string(&1, base))
    |> Stream.map(&zero_pad(&1, max_length))
    |> Enum.join(joiner)
    |> String.replace_prefix("", prefix)
  end

  # When numbers are converted from decimal to binary/hex
  # any leading zeroes are discarded, so we need to zero-pad
  # them to their expected length (ie. 8 for binary, 2 for hex)
  defp zero_pad(n, max_len) when byte_size(n) == byte_size(max_len), do: n
  defp zero_pad(n, max_len), do: String.rjust(n, max_len, ?0)

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
