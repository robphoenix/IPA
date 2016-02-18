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
    if Valid.Address.valid?(addr) do
      {:ok, %IPA.Address{
          address: addr,
          bin: IPA.Convert.addr_to_bin(addr),
          bits: IPA.Convert.addr_to_bits(addr),
          hex: IPA.Convert.addr_to_hex(addr),
          tuple: IPA.Convert.addr_to_tuple(addr),
          block: IPA.Helpers.block(addr)}}
    else
      {:error, "Not a valid IP address"}
    end
  end
end
