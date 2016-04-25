defmodule IPA do
  @moduledoc """
  Functions for working with IP addresses.

  Currently only compatible with IPv4 addresses.
  """

  @type ip :: addr | mask
  @type addr :: String.t
  @type mask :: String.t | non_neg_integer

  @addr_regex ~r/^(([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])\.){3}
                   ([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$/x

  @mask_regex ~r/^((1|0){1,8}\.){3}(1|0){1,8}$/

  @doc """
  Checks if the given dotted decimal IP address is valid.

  Uses a regular expression to check there is exactly
  4 integers between 0 & 255, inclusive, separated by dots.
  Taken from [here](http://www.regular-expressions.info/numericranges.html).
  Therefore does not currently take into consideration
  the fact that `127.1` can be considered a valid IP address
  that translates to `127.0.0.1`.

  ## Examples

      iex> IPA.valid_address?("192.168.0.1")
      true
      iex> IPA.valid_address?("8.8.8.8")
      true
      iex> IPA.valid_address?("10.0.0.256")
      false
      iex> IPA.valid_address?("10.0.0.")
      false
  """
  @spec valid_address?(addr) :: boolean
  def valid_address?(addr) when is_tuple(addr) do
    addr
    |> Tuple.to_list
    |> validate_ip_list
  end
  def valid_address?(addr) do
    cond do
      String.at(addr, 1) == "x" ->
        validate_hex(addr)
      String.at(addr, 1) == "b" ->
        validate_bin(addr)
      number_of_dots(addr) > 3 ->
        false
      number_of_dots(addr) <= 3 ->
        validate_dotted(addr)
    end
  end

  defp validate_hex(addr) do
    <<48, 120, a::binary-size(2), b::binary-size(2), c::binary-size(2), d::binary-size(2)>> = addr
    [a, b, c, d]
    |> Enum.map(&String.to_integer(&1, 16))
    |> validate_ip_list
  end

  defp validate_bin(addr) do
    <<48, 98, a::binary-size(8), b::binary-size(8), c::binary-size(8), d::binary-size(8)>> = addr
    [a, b, c, d]
    |> Enum.map(&String.to_integer(&1, 2))
    |> validate_ip_list
  end

  defp validate_dotted(addr) do
    addr = String.split(addr, ".")
    cond do
      Enum.any?(addr, fn(x) -> String.length(x) > 3 end) ->
        Enum.map(addr, &String.to_integer(&1, 2)) |> validate_ip_list
      true ->
        Enum.map(addr, &String.to_integer/1) |> validate_ip_list
    end
  end

  defp validate_ip_list(addr) when length(addr) === 4 do
    Enum.all?(addr, fn (x) -> x > -1 && x < 256 end)
  end
  defp validate_ip_list(_), do: false

  defp number_of_dots(addr) do
    addr
    |> String.graphemes
    |> Enum.filter(&(&1 == "."))
    |> length
  end


  @doc """
  Checks if the given subnet mask is valid.

  Works with CIDR notation, as well as dotted decimal and
  dotted binary.

  ## Examples

      iex> IPA.valid_mask?(24)
      true
      iex> IPA.valid_mask?(33)
      false
      iex> IPA.valid_mask?("255.255.255.0")
      true
      iex> IPA.valid_mask?("192.168.0.1")
      false
      iex> IPA.valid_mask?("11111111.11111111.11111111.00000000")
      true
      iex> IPA.valid_mask?("10101000.10101000.00000000.00000000")
      false
  """
  @spec valid_mask?(mask) :: boolean
  def valid_mask?(mask) when is_integer(mask) do
    case mask do
      mask when mask > 0 and mask < 33 -> true
      _ -> false
    end
  end
  def valid_mask?(mask) do
    if Regex.match?(@mask_regex, mask) do
      [h|t] = mask |> String.replace(".", "") |> String.to_char_list
      binary_validation(h, t, [])
    else
      [h|t] = mask
      |> String.split(".")
      |> Stream.map(&String.to_integer/1)
      |> Stream.map(&Integer.to_string(&1, 2))
      |> Enum.join
      |> String.to_char_list

      binary_validation(h, t, [])
    end
  end

  # Check to make sure that 1s don't follow 0s
  # or that the mask doesn't start with a 0
  defp binary_validation(_, [], _), do: true
  defp binary_validation(?0, _, []), do: false
  defp binary_validation(?1, _, ?0), do: false
  defp binary_validation(?1, [h|t], _) do
    binary_validation(h, t, ?1)
  end
  defp binary_validation(?0, [h|t], _) do
    binary_validation(h, t, ?0)
  end

  @doc """
  Converts CIDR notation to dotted decimal.

  ## Example

      iex> IPA.to_dotted_dec(24)
      "255.255.255.0"
  """
  @spec to_dotted_dec(ip) :: String.t
  def to_dotted_dec(mask) when is_integer(mask) do
    mask
    |> validate_and_transform_to_int_list
    |> Enum.join(".")
  end

  @doc """
  Converts a dotted decimal IP address/Subnet Mask, or a CIDR
  notation numerical Subnet Mask to a `0b` prefixed binary number.

  ## Example

      iex> IPA.to_binary("192.168.0.1")
      "0b11000000101010000000000000000001"
      iex> IPA.to_binary("255.255.255.0")
      "0b11111111111111111111111100000000"
      iex> IPA.to_binary(24)
      "0b11111111111111111111111100000000"
  """
  @spec to_binary(ip) :: String.t
  def to_binary(ip)

  def to_binary(addr) do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(2, 8, "", "0b")
  end

  @doc """
  Converts a dotted decimal IP address/Subnet Mask, or a CIDR
  notation numerical Subnet Mask to binary bits.

  ## Example

      iex> IPA.to_bits("192.168.0.1")
      "11000000.10101000.00000000.00000001"
      iex> IPA.to_bits("255.255.255.0")
      "11111111.11111111.11111111.00000000"
      iex> IPA.to_bits(24)
      "11111111.11111111.11111111.00000000"
  """
  @spec to_bits(ip) :: String.t
  def to_bits(ip)

  def to_bits(addr)  do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(2, 8, ".", "")
  end

  @doc """
  Converts a dotted decimal IP address/Subnet Mask, or a CIDR
  notation numerical Subnet Mask to a `0x` prefixed hexadecimal
  number.

  ## Example

      iex> IPA.to_hex("192.168.0.1")
      "0xC0A80001"
  """
  @spec to_hex(ip) :: String.t
  def to_hex(ip)

  def to_hex(addr) do
    addr
    |> validate_and_transform_to_int_list
    |> transform_addr(16, 2, "", "0x")
  end

  @doc """
  Converts a dotted decimal IP address or Subnet Mask, or a
  CIDR notation Subnet Mask, to a 4 element tuple, representing
  the 4 octets.

  ## Example

      iex> IPA.to_octets("192.168.0.1")
      {192, 168, 0, 1}
      iex> IPA.to_octets("255.255.255.0")
      {255, 255, 255, 0}
      iex> IPA.to_octets(24)
      {255, 255, 255, 0}
  """
  @spec to_octets(ip) :: {integer}
  def to_octets(ip) do
    ip
    |> validate_and_transform_to_int_list
    |> List.to_tuple
  end

  @doc """
  Converts a dotted decimal Subnet Mask to CIDR notation.

  ## Examples

      iex> IPA.to_cidr("255.255.255.0")
      24
  """
  def to_cidr(mask) do
    cond do
      Regex.match?(@mask_regex, mask) ->
        cond do
          valid_mask?(mask) ->
            mask
            |> String.replace(".", "")
            |> transform_to_cidr
          true ->
            raise SubnetError
        end
     true ->
        mask
        |> validate_and_transform_to_int_list
        |> Enum.map(&Integer.to_string(&1, 2))
        |> Enum.join
        |> transform_to_cidr
    end
  end

  defp transform_to_cidr(bin) do
    bin
    |> String.strip(?0)
    |> String.length
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
  Returns an atom describing which reserved block the address is a member of if it is a private address, returns `:public` otherwise.

  [Available blocks](https://en.wikipedia.org/wiki/Reserved_IP_addresses):

  | Atom | Range(s) | Purpose |
  |:----:|:--------:|:-------:|
  | `:this_network` | `0.0.0.0/8` | Used for broadcast messages to the current "this" network as specified by RFC 1700, page 4. |
  | `:rfc1918` | `10.0.0.0/8` `172.16.0.0/12` `192.168.0.0/16` | Used for local communications within a private network as specified by RFC 1918. |
  | `:rfc6598` | `100.64.0.0/10` | Used for communications between a service provider and its subscribers when using a Carrier-grade NAT, as specified by RFC 6598. |
  | `:loopback` | `127.0.0.0/8` | Used for loopback addresses to the local host, as specified by RFC 990. |
  | `:link_local` | `169.254.0.0/16` | Used for link-local addresses between two hosts on a single link when no IP address is otherwise specified, such as would have normally been retrieved from a DHCP server, as specified by RFC 3927. |
  | `:rfc5736` | `192.0.0.0/24` | Used for the IANA IPv4 Special Purpose Address Registry as specified by RFC 5736. |
  | `:rfc5737` | `192.0.2.0/24` `198.51.100.0/24` `203.0.113.0/24` | Assigned as "TEST-NET" in RFC 5737 for use solely in documentation and example source code and should not be used publicly. |
  | `:rfc3068` | `192.88.99.0/24` | Used by 6to4 anycast relays as specified by RFC 3068. |
  | `:rfc2544` | `198.18.0.0/15` | Used for testing of inter-network communications between two separate subnets as specified in RFC 2544. |
  | `:multicast` | `224.0.0.0/4` | Reserved for multicast assignments as specified in RFC 5771. `233.252.0.0/24` is assigned as "MCAST-TEST-NET" for use solely in documentation and example source code. |
  | `:future` | `240.0.0.0/4` | Reserved for future use, as specified by RFC 6890. |
  | `:limited_broadcast` | `255.255.255.255/32` | Reserved for the "limited broadcast" destination address, as specified by RFC 6890. |
  | `:public` | | All other addresses are public. |

  ## Examples

      iex> IPA.block("8.8.8.8")
      :public
      iex> IPA.block("192.168.0.1")
      :rfc1918
  """
  @spec block(String.t) :: atom
  def block(addr) do
    addr
    |> to_octets
    |> which_block?
  end

  # check if address is valid, and if it is transform
  # it into a list of integers.
  defp validate_and_transform_to_int_list(mask) when is_integer(mask) do
    if valid_mask?(mask) do
      (List.duplicate(255, div(mask, 8)) ++ decode_mask_bits(rem(mask, 8)))
      |> add_zero_bits
    else
      raise SubnetError
    end
  end
  defp validate_and_transform_to_int_list(addr) do
    if valid_address?(addr) do
      for n <- String.split(addr, "."), do: String.to_integer(n)
    else
      raise IPError
    end
  end

  defp add_zero_bits(octets_list) when length(octets_list) == 4, do: octets_list
  defp add_zero_bits(octets_list) do
    add_zero_bits(octets_list ++ [0])
  end

  defp decode_mask_bits(0), do: []
  defp decode_mask_bits(1), do: [128]
  defp decode_mask_bits(2), do: [192]
  defp decode_mask_bits(3), do: [224]
  defp decode_mask_bits(4), do: [240]
  defp decode_mask_bits(5), do: [248]
  defp decode_mask_bits(6), do: [252]
  defp decode_mask_bits(7), do: [254]
  defp decode_mask_bits(8), do: [255]

  # Convert address to different numerical base,
  # (ie. 2 for binary, 16 for hex), left-pads,
  # joins and adds a prefix
  defp transform_addr(addr, base, max_length, joiner, prefix) do
    addr
    |> Stream.map(&Integer.to_string(&1, base))
    |> Stream.map(&left_pad(&1, max_length, ?0))
    |> Enum.join(joiner)
    |> String.replace_prefix("", prefix)
  end

  # When numbers are converted from decimal to binary/hex
  # any leading zeroes are discarded, so we need to left-pad
  # them to their expected length (ie. 8 for binary, 2 for hex)
  defp left_pad(n, max_len, _) when byte_size(n) == byte_size(max_len), do: n
  defp left_pad(n, max_len, char), do: String.rjust(n, max_len, char)

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
