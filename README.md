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

The following functions are available in the `IPA` module:

Check if a dotted decimal address is valid:

```elixir
IPA.valid_address?("192.168.0.1")   #=> true
IPA.valid_address?("192.168.0.256") #=> false
IPA.valid_address?("192.168.0")     #=> false
IPA.valid_address?("192.168.0.1.1") #=> false
```

> This validity is based on whether the given address contains 4 numbers,
> separated by 3 dots, between 0 & 255, inclusive. It is slightly imperfect,
> not recognising the fact that 127.1 can be considered a valid IP address
> that translates to 127.0.0.1, just so you know.

Check if a dotted decimal or CIDR notation subnet mask is valid:

```elixir
IPA.valid_mask?("255.255.255.0") #=> true
IPA.valid_mask?("192.168.0.1")   #=> false
IPA.valid_mask?(24)              #=> true
IPA.valid_mask?(33)              #=> false
```

Find out if the address is part of a reserved private address block
(ie. NOT a public address):

```elixir
IPA.reserved?("192.168.0.1") #=> true
IPA.reserved?("8.8.8.8")     #=> false
```

Find out which reserved block of addresses an address is a part of. If not
reserved it will be public, obvs.  A full list of reserved blocks can be found
in the docs:

```elixir
IPA.block("192.168.0.1") #=> :rfc1918
IPA.block("10.0.1.0")    #=> :rfc1918
IPA.block("127.0.0.1")   #=> :loopback
IPA.block("8.8.8.8")     #=> :public
```

Transform a dotted decimal address into it's hexadecimal, binary or
dotted binary representation, or get the octets as a 4 element tuple:

```elixir
IPA.to_hex("192.168.0.1")    #=> "0xC0A80001"

IPA.to_binary("192.168.0.1") #=> "0b11000000101010000000000000000001"

IPA.to_bits("192.168.0.1")   #=> "11000000.10101000.00000000.00000001"

IPA.to_octets("192.168.0.1") #=> {192, 168, 0, 1}
```

You can also use the following functions with subnet masks, both dotted
decimal, and CIDR notation:

```elixir
IPA.to_bits("255.255.255.0")   #=> "11111111.11111111.11111111.00000000"
IPA.to_bits(24)                #=> "11111111.11111111.11111111.00000000"

IPA.to_binary("255.255.255.0") #=> "0b11111111111111111111111100000000"
IPA.to_binary(24)              #=> "0b11111111111111111111111100000000"

IPA.to_octets("255.255.255.0") #=> {255, 255, 255, 0}
IPA.to_octets(24)              #=> {255, 255, 255, 0}

IPA.to_dotted_dec(24)          #=> "255.255.255.0"

IPA.to_cidr("255.255.255.0")   #=> 24
```

## TODO

**this** - *"You should probably parse to some internal representation that requires the least parsing or generating...which might just be a binary of some kind. Or you could just use what Erlang likes to, which is the 4-tuple."

- validity checks for hex, binary & tuple masks
- validity checks for hex, binary, bits & tuple addresses
- ability to use hex, binary, bits & tuple notation with `to_dotted_decimal`
- ability to use hex, bits & tuple notation with `to_binary`
- ability to use hex, binary & tuple notation with `to_bits`
- ability to use cidr, binary, bits & tuple notation with `to_hex`
- ability to use hex, binary & bits notation with `to_octets`
- ability to use hex, binary, bits & tuple notation with `to_cidr`
- improve transformations & validation

## Docs

Docs are available via `ExDoc`, run `mix docs` and open up `doc/index.html`.

## Tests

Run `mix test`. DocTests included.

## Caveat

Honestly, I don't know how much time I'm actually going to be able to dedicate
to this project, so maybe think carefully before using it in production code
(ha, high hopes!), but perhaps it can at least provide a starting point for
something better?

## Contributing

Please fork and send pull requests (preferably from non-master
branches), including tests (`ExUnit.Case`).

Report bugs and request features via Issues; PRs are even better!

## License

The MIT License (MIT)

Copyright (c) 2014 CargoSense, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

