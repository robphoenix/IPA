defmodule IPATest do
  use ExUnit.Case
  doctest IPA

  ExUnit.configure trace: true


  test "valid address" do
    assert IPA.valid?("192.168.0.1")
  end

  test "invalid addresses" do
    refute IPA.valid?("192.168.0.256")
    refute IPA.valid?("192.168.0")
    refute IPA.valid?("192.168.0.1.1")
    refute IPA.valid?("192.168.0.1.")
  end

  test "dot decimal address to hex" do
    assert IPA.to_hex("192.168.0.1") == "0xC0A80001"
  end

  test "dot decimal address to bits" do
    assert IPA.to_bits("192.168.0.1") == "11000000.10101000.00000000.00000001"
  end

  test "dot decimal address to binary" do
    assert IPA.to_binary("192.168.0.1") == "0b11000000101010000000000000000001"
  end

  test "dot decimal address to octets" do
    assert IPA.to_octets("192.168.0.1") == {192, 168, 0, 1}
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
    assert IPA.reserved?("0.0.0.0")
  end
end
