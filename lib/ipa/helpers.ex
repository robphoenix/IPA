defmodule IPA.Helpers do
  @moduledoc """
  Helper functions
  """

  @doc """
  Returns true if an IP address octet is valid; in the range 0..255
  """
  def valid_octet?(octet) when octet in 0..255, do: true
  def valid_octet?(_), do: false

end
