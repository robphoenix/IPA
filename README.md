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

As such, it enables the creation of an ip address struct, using the
`IPA.address/1` function.  All the functions in this library expect the IP
address to be given as a string.

```elixir
{:ok, ip} = IPA.address("192.168.0.1")
# => {:ok, %IPA.Address{...}}
```
    
This struct contains transformations of, and information about, the given IP
address:

```elixir
ip.address
# => "192.168.0.1"
ip.binary
# => "0b11000000101010000000000000000001"
ip.bits
# => "11000000.10101000.00000000.00000001"
ip.block
# => :rfc1918
ip.hex
# => "0xC0A80001"
ip.octets
# => {192, 168, 0, 1}
ip.version
# => 4
ip.reserved
# => true
```

You can also use `IPA.address!/1` to access the same data:

```elixir
ip = IPA.Address!("192.168.0.1")
# => %IPA.Address{...}
```

If you don't need the struct, then you can just use the functions used to build
the struct, available in the `IPA.Address` module:

```elixir
# Check if an address is valid:
IPA.Address.valid?("192.168.0.1") # => true
IPA.Address.valid?("192.168.0.256") # => false
IPA.Address.valid?("192.168.0") # => false
IPA.Address.valid?("192.168.0.1.1") # => false

# This validity is based on whether the given address contains 4 numbers,
# separated by 3 dots, between 0 & 255, inclusive. It is slightly imperfect,
# not recognising the fact that 127.1 can be considered a valid IP address
# that translates to 127.0.0.1, just so you know.

# Find out if the address is part of a reserved private address block
# (ie. NOT a public address):
IPA.Address.reserved?("192.168.0.1") # => true
IPA.Address.reserved?("8.8.8.8") # => false

# Find out which reserved block of addresses an address is a part of. If not reserved
# it will be public, obvs.  A full list of reserved blocks can be found in the docs:
IPA.Address.block("192.168.0.1") # => :rfc1918
IPA.Address.block("10.0.1.0") # => :rfc1918
IPA.Address.block("127.0.0.1") # => :loopback
IPA.Address.block("8.8.8.8") # => :public

# And transform a dotted decimal address into it's hexadecimal, binary or
# dotted binary representation, or get the octets as a 4 element tuple:
IPA.Address.to_hex("192.168.0.1")
# => "0xC0A80001"
IPA.Address.to_binary("192.168.0.1")
# => "0b11000000101010000000000000000001"
IPA.Address.to_bits("192.168.0.1")
# => "11000000.10101000.00000000.00000001"
IPA.Address.to_octets("192.168.0.1")
# => {192, 168, 0, 1}

# There's no reason you can't use these functions with subnet masks:
IPA.Address.to_bits("255.255.0.0")
# => "11111111.11111111.00000000.00000000"

# But I am hoping to get some subnet functions implemented soon.
```

## Docs

Docs are available via `ExDoc`, run `mix docs` and open up `doc/index.html`.

## Tests

Run `mix test`.

```elixir
IPATest
  * address delegate error when < 4 octets  * address delegate error when < 4 octets (0.03ms)
  * dot decimal address to bits  * dot decimal address to bits (8.2ms)
  * dot decimal address to octets  * dot decimal address to octets (0.02ms)
  * doc at IPA.Address.block/1 (2)  * doc at IPA.Address.block/1 (2) (0.01ms)
  * address delegate error when octet > 255  * address delegate error when octet > 255 (0.02ms)
  * address delegate error when > 4 octets  * address delegate error when > 4 octets (0.01ms)
  * public address is not reserved  * public address is not reserved (0.01ms)
  * dot decimal address to binary  * dot decimal address to binary (0.04ms)
  * valid address  * valid address (0.01ms)
  * address delegate error when octet < 0  * address delegate error when octet < 0 (0.01ms)
  * doc at IPA.Address.to_octets/1 (6)  * doc at IPA.Address.to_octets/1 (6) (0.01ms)
  * doc at IPA.Address.to_hex/1 (5)  * doc at IPA.Address.to_hex/1 (5) (0.03ms)
  * dot decimal address to hex  * dot decimal address to hex (0.03ms)
  * doc at IPA.Address.to_bits/1 (4)  * doc at IPA.Address.to_bits/1 (4) (0.02ms)
  * doc at IPA.Address.to_binary/1 (3)  * doc at IPA.Address.to_binary/1 (3) (0.02ms)
  * address delegate returns expected  * address delegate returns expected (8.3ms)
  * private addresses are reserved  * private addresses are reserved (0.05ms)
  * invalid addresses  * invalid addresses (0.03ms)
  * doc at IPA.Address.address/1 (1)  * doc at IPA.Address.address/1 (1) (0.1ms)


Finished in 0.3 seconds (0.3s on load, 0.03s on tests)
19 tests, 0 failures
```

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

