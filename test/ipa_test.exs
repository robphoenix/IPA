defmodule IPATest do
  use ExUnit.Case
  doctest IPA

  alias Valid.Address
  alias IPA.Helpers

  ExUnit.configure trace: true

  @expected {:ok, %IPA.Address{
                address: "192.168.0.1",
                bin: "0b11000000101010000000000000000001",
                bits: "11000000.10101000.00000000.00000001",
                block: :rfc1918,
                hex: "0xC0A80001",
                tuple: {192, 168, 0, 1},
                version: 4}}

  @invalid {:error, "Not a valid IP address"}

  test "address delegate returns expected" do
    assert IPA.address("192.168.0.1") == @expected
  end

  test "address delegate error when octet > 255" do
    assert IPA.address("192.168.0.256") == @invalid
  end

  test "address delegate error when octet < 0" do
    assert IPA.address("192.168.0.-1") == @invalid
  end

  test "address delegate error when < 4 octets" do
    assert IPA.address("192.168.0") == @invalid
    assert IPA.address("192.168.0.") == @invalid
  end

  test "address delegate error when > 4 octets" do
    assert IPA.address("192.168.0.1.1") == @invalid
    assert IPA.address("192.168.0.1.1.") == @invalid
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
    {:ok, %{hex: hex}} = IPA.address("192.168.0.1")
    assert hex == "0xC0A80001"
  end

  test "dot decimal address to bits" do
    {:ok, %{bits: bits}} = IPA.address("192.168.0.1")
    assert bits == "11000000.10101000.00000000.00000001"
  end

  test "dot decimal address to binary" do
    {:ok, %{bin: bin}} = IPA.address("192.168.0.1")
    assert bin == "0b11000000101010000000000000000001"
  end

  test "dot decimal address to tuple" do
    {:ok, %{tuple: tuple}} = IPA.address("192.168.0.1")
    assert tuple == {192, 168, 0, 1}
  end
end
