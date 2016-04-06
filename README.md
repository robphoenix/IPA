# IPA

A pale, hoppy library for working with Internet Protocol Addresses.

> Currently only supports individual addresses and not networks, and only
> classic IPv4, not modern IPv6, sorry.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ipa to your list of dependencies in `mix.exs`:

        def deps do
          [{:ipa, "~> 0.0.1"}]
        end

  2. Ensure ipa is started before your application:

        def application do
          [applications: [:ipa]]
        end
        
## Usage

This library was initially a direct port of Python's
[netaddr](https://github.com/drkjam/netaddr) library as a means to learning
Elixir.
As such, it enables the creation of an ip address struct:

    test
