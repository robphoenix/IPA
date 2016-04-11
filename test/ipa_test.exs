defmodule IPATest do
  use ExUnit.Case
  doctest IPA

  ExUnit.configure trace: true

  @valid_ip "192.168.0.1"
  @invalid_ip "192.168.0.256"

  test "valid address" do
    assert IPA.valid?(@valid_ip)
  end

  test "invalid addresses" do
    refute IPA.valid?(@invalid_ip)
    refute IPA.valid?("192.168.0")
    refute IPA.valid?("192.168.0.1.1")
    refute IPA.valid?("192.168.0.1.")
  end

  test "dot decimal address to hex" do
    assert IPA.to_hex(@valid_ip) == "0xC0A80001"
  end

  test "invalid dot decimal address to hex raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_hex(@invalid_ip)
    end
  end

  test "dot decimal address to bits" do
    assert IPA.to_bits(@valid_ip) == "11000000.10101000.00000000.00000001"
  end

  test "invalid dot decimal address to bits raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_bits(@invalid_ip)
    end
  end

  test "dot decimal address to binary" do
    assert IPA.to_binary(@valid_ip) == "0b11000000101010000000000000000001"
  end

  test "invalid dot decimal address to binary raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_binary(@invalid_ip)
    end
  end

  test "dot decimal address to octets" do
    assert IPA.to_octets(@valid_ip) == {192, 168, 0, 1}
  end

  test "invalid dot decimal address to octets raises error" do
    assert_raise IPError, "Invalid IP Address", fn ->
      IPA.to_octets(@invalid_ip)
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
