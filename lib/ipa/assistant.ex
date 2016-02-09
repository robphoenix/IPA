defmodule IPA.Assistant do

  def valid_octet?(octet) when octet >= 0 and octet < 256, do: true
  def valid_octet?(_), do: false

end
