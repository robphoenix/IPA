defmodule IPATest do
  use ExUnit.Case
  #doctest IPA

  alias IPA.Address

  ExUnit.configure trace: true

  @expected {:ok, %IPA.Address{
                address: "192.168.0.1",
                binary: "0b11000000101010000000000000000001",
                bits: "11000000.10101000.00000000.00000001",
                block: :rfc1918,
                hex: "0xC0A80001",
                octets: {192, 168, 0, 1},
                version: 4,
                reserved: true}}

  test "address delegate returns expected" do
    assert IPA.address("192.168.0.1") == @expected
  end

  test "address delegate error when octet > 255" do
    assert IPA.address("192.168.0.256") == {:error, :invalid_ipv4_address}
  end

  test "address delegate error when octet < 0" do
    assert IPA.address("192.168.0.-1") == {:error, :invalid_ipv4_address}
  end

  test "address delegate error when < 4 octets" do
    assert IPA.address("192.168.0") == {:error, :invalid_ipv4_address}
    assert IPA.address("192.168.0.") == {:error, :invalid_ipv4_address}
  end

  test "address delegate error when > 4 octets" do
    assert IPA.address("192.168.0.1.1") == {:error, :invalid_ipv4_address}
    assert IPA.address("192.168.0.1.1.") == {:error, :invalid_ipv4_address}
  end

  test "valid address" do
    assert Address.valid?("192.168.0.1") == true
  end

  test "invalid addresses" do
    assert Address.valid?("192.168.0.256") == false
    assert Address.valid?("192.168.0") == false
    assert Address.valid?("192.168.0.1.1") == false
    assert Address.valid?("192.168.0.1.") == false
  end

  test "dot decimal address to hex" do
    assert Address.to_hex("192.168.0.1") == "0xC0A80001"
  end

  test "dot decimal address to bits" do
    assert Address.to_bits("192.168.0.1") == "11000000.10101000.00000000.00000001"
  end

  test "dot decimal address to binary" do
    assert Address.to_binary("192.168.0.1") == "0b11000000101010000000000000000001"
  end

  test "dot decimal address to octets" do
    assert Address.to_octets("192.168.0.1") == {192, 168, 0, 1}
  end

  test "public address is not reserved" do
    assert Address.reserved?("8.8.8.8") == false
  end

  test "private addresses are reserved" do
    assert Address.reserved?("0.0.0.0") == true
    assert Address.reserved?("10.0.0.0") == true
    assert Address.reserved?("100.64.0.0") == true
    assert Address.reserved?("127.0.0.0") == true
    assert Address.reserved?("169.254.0.0") == true
    assert Address.reserved?("172.16.0.0") == true
    assert Address.reserved?("192.0.0.0") == true
    assert Address.reserved?("192.0.2.0") == true
    assert Address.reserved?("192.88.99.0") == true
    assert Address.reserved?("192.168.0.0") == true
    assert Address.reserved?("198.18.0.0") == true
    assert Address.reserved?("198.51.100.0") == true
    assert Address.reserved?("203.0.113.0") == true
    assert Address.reserved?("224.0.0.0") == true
    assert Address.reserved?("240.0.0.0") == true
    assert Address.reserved?("255.255.255.255") == true
    assert Address.reserved?("0.0.0.0") == true
  end
end
