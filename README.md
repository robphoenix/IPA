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

    {:ok, ip} = IPA.address("192.168.0.1")
    # => {:ok, %IPA.Address{...}}
    
This struct contains transformations of, and information about, the given IP
address:

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
    
You can also use `IPA.address!/1` to access the same data:

    ip = IPA.Address("192.168.0.1")
    # => %IPA.Address{...}
    
If you don't need the struct, then you can just use the functions used to build
the struct, available in the `IPA.Address` module:

    # Check if an address is valid:
    IPA.Address.valid?("192.168.0.1") # => true
    IPA.Address.valid?("192.168.0.256") # => false
    IPA.Address.valid?("192.168.0") # => false
    IPA.Address.valid?("192.168.0.1.1") # => false
    
    # This validity is based on whether the given address contains 4 numbers,
    # separated by 3 dots, between 0 & 255, inclusive. It is slightly imperfect,
    # not recognising the fact that 127.1 can be considered a valid IP address
    # that translates to 127.0.0.1, just so you know.

    # Find out if the address is part of a reserved private address block (ie.
    NOT a public address):
    IPA.Address.reserved?("192.168.0.1") # => true
    IPA.Address.reserved?("8.8.8.8") # => false
    
    # Find out whic reserved block of addresses an address is a part of. If not reserved
    it will be public, obvs:
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
    
