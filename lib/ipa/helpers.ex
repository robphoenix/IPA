defmodule IPA.Helpers do
  @moduledoc """
  Helper functions
  """

  @doc """
  Returns true if an IP address octet is valid; in the range 0..255
  """
  def valid_octet?(octet) when octet in 0..255, do: true
  def valid_octet?(_), do: false

  def block(addr) do
    addr
    |> IPA.Convert.addr_to_tuple
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
