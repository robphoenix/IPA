defprotocol Valid do
  @doc "Returns true if address is considered nominally valid"
  def valid?(address)

end

defimpl Valid, for: Address do
  def valid?(ip) do
    ip_to_list = ip |> String.split(".")
    case length(ip_to_list) do
      4 ->
        ip_to_list
        |> Enum.map(&String.to_integer/1)
        |> Enum.all?(&Address.valid_octet?/1)
      _ ->
        false
    end
  end
end
