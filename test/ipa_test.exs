defmodule IPATest do
  use ExUnit.Case
  doctest IPA

  ExUnit.configure exclude: :pending, trace: true

  test "validity of dotted decimal addresses" do
    assert IPA.valid_address?("192.168.0.1")
    assert IPA.valid_address?("10.0.0.254")
    assert IPA.valid_address?("8.8.8.8")
    refute IPA.valid_address?("192.168.256.256")
    refute IPA.valid_address?("192.168.0")
    refute IPA.valid_address?("192.168")
    refute IPA.valid_address?("192.168.0.1.1")
    refute IPA.valid_address?("192.168.0.1.1.")
    refute IPA.valid_address?("192.168.0.1.")
  end

  test "validity of binary addresses" do
    assert IPA.valid_address?("0b11000000101010000000000000000001")
    assert IPA.valid_address?("0b00001000000010000000100000001000")
    assert IPA.valid_address?("0b00001010000000000000000011111110")
    refute IPA.valid_address?("0b11111111111111111111111100000002")
    refute IPA.valid_address?("11111111111111111111111100000001")
    refute IPA.valid_address?("0b111111111111111111111111")
    refute IPA.valid_address?("0b1100000010101000000000000000000111111111")
  end

  test "validity of bits addresses" do
    assert IPA.valid_address?("11000000.10101000.00000000.00000001")
    assert IPA.valid_address?("00001010.00000000.00000000.11111110")
    assert IPA.valid_address?("00001000.00001000.00001000.00001000")
    refute IPA.valid_address?("11111111.11111111.11111111.00000002")
    refute IPA.valid_address?("0b111111.11111111.11111111.11")
    refute IPA.valid_address?("0b110000.00101010.00000000.00000000.11111111")
  end

  test "validity of hex addresses" do
    assert IPA.valid_address?("0xC0A80001")
    assert IPA.valid_address?("0x08080808")
    assert IPA.valid_address?("0x0A0000FE")
    refute IPA.valid_address?("0A0000FE")
    refute IPA.valid_address?("0x0A0000FEFF")
    refute IPA.valid_address?("0x0A0000")
  end

  test "validity of octets addresses" do
    assert IPA.valid_address?({192, 168, 0, 1})
    assert IPA.valid_address?({10, 0, 0, 254})
    assert IPA.valid_address?({8, 8, 8, 8})
    refute IPA.valid_address?({192, 168, 0, 256})
    refute IPA.valid_address?({192, 168, 1})
    refute IPA.valid_address?({192, 168, 1, 1, 1})
  end

  test "addresses to hex" do
    assert IPA.to_hex("192.168.0.1") == "0xC0A80001"
    assert IPA.to_hex("255.255.255.0") == "0xFFFFFF00"
    assert IPA.to_hex(24) == "0xFFFFFF00"
    assert IPA.to_hex({192, 168, 0, 1}) == "0xC0A80001"
    assert IPA.to_hex("0b11000000101010000000000000000001") == "0xC0A80001"
    assert IPA.to_hex("11000000.10101000.00000000.00000001") == "0xC0A80001"
  end

  test "addresses to bits" do
    assert IPA.to_bits("192.168.0.1") == "11000000.10101000.00000000.00000001"
    assert IPA.to_bits({192, 168, 0, 1}) == "11000000.10101000.00000000.00000001"
    assert IPA.to_bits("0b11000000101010000000000000000001") == "11000000.10101000.00000000.00000001"
    assert IPA.to_bits("0xC0A80001") == "11000000.10101000.00000000.00000001"
    assert IPA.to_bits(24) == "11111111.11111111.11111111.00000000"
  end

  test "addresses to binary" do
    assert IPA.to_binary("192.168.0.1") == "0b11000000101010000000000000000001"
    assert IPA.to_binary({192, 168, 0, 1}) == "0b11000000101010000000000000000001"
    assert IPA.to_binary("0xC0A80001") == "0b11000000101010000000000000000001"
    assert IPA.to_binary("11000000.10101000.00000000.00000001") == "0b11000000101010000000000000000001"
    assert IPA.to_binary(24) == "0b11111111111111111111111100000000"
  end

  test "addresses to octets" do
    assert IPA.to_octets("192.168.0.1") == {192, 168, 0, 1}
    assert IPA.to_octets("0b11000000101010000000000000000001") == {192, 168, 0, 1}
    assert IPA.to_octets("0xC0A80001") == {192, 168, 0, 1}
    assert IPA.to_octets("11000000.10101000.00000000.00000001") == {192, 168, 0, 1}
    assert IPA.to_octets(24) == {255, 255, 255, 0}
  end

  test "addresses to dotted decimal" do
    assert IPA.to_dotted_dec({192, 168, 0, 1}) == "192.168.0.1"
    assert IPA.to_dotted_dec("0b11000000101010000000000000000001") == "192.168.0.1"
    assert IPA.to_dotted_dec("0xC0A80001") == "192.168.0.1"
    assert IPA.to_dotted_dec("11000000.10101000.00000000.00000001") == "192.168.0.1"
    assert IPA.to_dotted_dec(24) == "255.255.255.0"
  end

  test "invalid dot decimal address to binary raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_binary("192.168.256.256")
    end
  end

  test "invalid dot decimal address to octets raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_octets("192.168.256.256")
    end
  end

  test "invalid dot decimal address to hex raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_hex("192.168.256.256")
    end
  end

  test "invalid dot decimal address to bits raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_bits("192.168.256.256")
    end
  end

  test "valid subnet mask" do
    assert IPA.valid_mask?(24)
    assert IPA.valid_mask?("255.255.255.0")
    assert IPA.valid_mask?("11111111.11111111.11111111.00000000")
    assert IPA.valid_mask?("0xFFFFFF00")
    assert IPA.valid_mask?("0b11111111111111111111111100000000")
    assert IPA.valid_mask?({255, 255, 255, 0})
  end

  test "invalid subnet masks" do
    refute IPA.valid_mask?("11111111.00000000.11111111.00000000")
    refute IPA.valid_mask?("10101000.10101000.10101000.10101000")
    refute IPA.valid_mask?("00000000.00000000.00000000.00000000")
    refute IPA.valid_mask?("192.168.0.1")
    refute IPA.valid_mask?("256.256.0.0")
    refute IPA.valid_mask?(0)
    refute IPA.valid_mask?(33)
    refute IPA.valid_mask?("0b11000000101010000000000000000001")
    refute IPA.valid_mask?("0xC0A80001")
  end

  test "mask to cidr" do
    assert IPA.to_cidr("255.255.255.0") == 24
    assert IPA.to_cidr("0xFFFFFF00") == 24
    assert IPA.to_cidr("0b11111111111111111111111100000000") == 24
    assert IPA.to_cidr({255, 255, 255, 0}) == 24
    assert IPA.to_cidr("11111111.11111111.11111111.00000000") == 24
  end

  test "invalid dot decimal mask to cidr raises error" do
    assert_raise SubnetError, "Invalid Subnet Mask", fn ->
      IPA.to_cidr("192.168.0.1")
    end
  end

  test "public address is not reserved" do
    refute IPA.reserved?("8.8.8.8")
  end

  test "private addresses are reserved" do
    assert IPA.reserved?("0.0.0.0")
    assert IPA.reserved?("10.0.0.0")
    assert IPA.reserved?("100.64.0.0")
    assert IPA.reserved?("127.0.0.0")
    assert IPA.reserved?("169.254.0.0")
    assert IPA.reserved?("172.16.0.0")
    assert IPA.reserved?("192.0.0.0")
    assert IPA.reserved?("192.0.2.0")
    assert IPA.reserved?("192.88.99.0")
    assert IPA.reserved?("192.168.0.0")
    assert IPA.reserved?("198.18.0.0")
    assert IPA.reserved?("198.51.100.0")
    assert IPA.reserved?("203.0.113.0")
    assert IPA.reserved?("224.0.0.0")
    assert IPA.reserved?("240.0.0.0")
    assert IPA.reserved?("255.255.255.255")
  end

  test "IP Address blocks" do
    assert IPA.block("8.8.8.8") == :public
    assert IPA.block("0.0.0.0") == :this_network
    assert IPA.block("10.0.0.0") == :rfc1918
    assert IPA.block("100.64.0.0") == :rfc6598
    assert IPA.block("127.0.0.0") == :loopback
    assert IPA.block("169.254.0.0") == :link_local
    assert IPA.block("172.16.0.0") == :rfc1918
    assert IPA.block("192.0.0.0") == :rfc5736
    assert IPA.block("192.0.2.0") == :rfc5737
    assert IPA.block("192.88.99.0") == :rfc3068
    assert IPA.block("192.168.0.0") == :rfc1918
    assert IPA.block("198.18.0.0") == :rfc2544
    assert IPA.block("198.51.100.0") == :rfc5737
    assert IPA.block("203.0.113.0") == :rfc5737
    assert IPA.block("224.0.0.0") == :multicast
    assert IPA.block("240.0.0.0") == :future
    assert IPA.block("255.255.255.255") == :limited_broadcast
  end
end
