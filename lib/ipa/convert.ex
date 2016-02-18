defmodule IPA.Convert do
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
end
