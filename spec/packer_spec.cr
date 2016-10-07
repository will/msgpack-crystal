require "./spec_helper"

describe "MessagePack::Packer" do
  it_packs(nil, UInt8[0xC0])

  it_packs(false, UInt8[0xC2])
  it_packs(true, UInt8[0xC3])

  it_packs(1.0.to_f32, UInt8[0xCA, 0x3F, 0x80, 0x00, 0x00])
  it_packs(1.0.to_f64, UInt8[0xCB, 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])

  it_packs("", UInt8[0xA0])
  it_packs("hello world", UInt8[0xAB] + "hello world".bytes)
  it_packs("x" * 200, UInt8[0xD9, 200] + ("x" * 200).bytes)
  it_packs("x" * 0xdddd, UInt8[0xDA, 0xDD, 0xDD] + ("x" * 0xdddd).bytes)
  it_packs("x" * 0x10000, UInt8[0xDB, 0x00, 0x01, 0x00, 0x00] + ("x" * 0x10000).bytes)

  describe "bin 8 (0xC4)" do
    # invalid byte sequence for UTF-8 (just a binary)
    it_packs(Bytes[0x08, 0xE7], UInt8[0xC4, 0x02] + UInt8[0x08, 0xE7])

    # valid byte sequence for UTF-8 ("好".bytes # => [0xE5, 0xA5, 0xBD])
    it_packs(Bytes[0xE5, 0xA5, 0xBD], UInt8[0xC4, 0x03] + UInt8[0xE5, 0xA5, 0xBD])
  end
  describe "bin 16 (0xC5)" do
    # invalid byte sequence for UTF-8 (just a binary)
    it_packs(as_slice(UInt8[0x08, 0xE7] * 0x100), UInt8[0xC5, 0x02, 0x00] + UInt8[0x08, 0xE7] * 0x100)
    # valid byte sequence for UTF-8 ("好".bytes # => [0xE5, 0xA5, 0xBD])
    it_packs(as_slice(UInt8[0xE5, 0xA5, 0xBD] * 0x100), UInt8[0xC5, 0x03, 0x00] + UInt8[0xE5, 0xA5, 0xBD] * 0x100)
  end
  describe "bin 32 (0xC6)" do
    # invalid byte sequence for UTF-8 (just a binary)
    it_packs(as_slice(UInt8[0x08, 0xE7] * 0x10000), UInt8[0xC6, 0x00, 0x02, 0x00, 0x00] + UInt8[0x08, 0xE7] * 0x10000)

    # valid byte sequence for UTF-8 ("好".bytes # => [0xE5, 0xA5, 0xBD])
    it_packs(as_slice(UInt8[0xE5, 0xA5, 0xBD] * 0x10000), UInt8[0xC6, 0x00, 0x03, 0x00, 0x00] + UInt8[0xE5, 0xA5, 0xBD] * 0x10000)
  end
  it_packs(([] of Type), UInt8[0x90])
  it_packs(Int8[1, 2], UInt8[0x92, 0x01, 0x02])
  it_packs(Array.new(0x111, false), UInt8[0xDC, 0x01, 0x11] + Array.new(0x111, 0xc2u8))
  it_packs(Array.new(0x11111, false), UInt8[0xDD, 0x00, 0x01, 0x11, 0x11] + Array.new(0x11111, 0xc2_u8))

  it_packs(({} of Type => Type), UInt8[0x80])
  it_packs({"foo" => "bar"}, UInt8[0x81, 0xA3] + "foo".bytes + UInt8[0xA3] + "bar".bytes)

  it "packs to the IO" do
    io = MemoryIO.new
    packer = MessagePack::Packer.new(io)
    packer.write(1.to_i8)

    io.to_slice.should eq Bytes.new(UInt8[0x01].to_unsafe, 1)
  end

  context "packs numbers to the smallest size possible according to the value" do
    it_packs([1, 2, 3], UInt8[147, 1, 2, 3])
  end
end
