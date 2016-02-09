defmodule IPA do
  defdelegate address(addr), to: IPA.Address
end
