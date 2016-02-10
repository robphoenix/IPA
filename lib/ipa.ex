defmodule IPA do
  @moduledoc """
  Public API that delegates to internal functions
  """

  defdelegate address(addr), to: IPA.Address
end
