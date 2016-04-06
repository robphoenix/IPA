defmodule IPA do
  @moduledoc """
  Module containing a delegated function for creating an
  IP address struct, providing a slightly simpler API.
  """

  defdelegate address(addr), to: IPA.Address
  defdelegate address!(addr), to: IPA.Address
end
