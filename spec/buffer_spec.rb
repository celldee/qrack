# buffer_spec.rb

require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib qrack]))

describe Qrack::Transport::Buffer do
	
	it 'should have empty string contents when created without data' do
		buf = Qrack::Transport::Buffer.new
    buf.contents.should == ''
  end

  it 'should be able to initialize with data' do
    buf = Qrack::Transport::Buffer.new('abc')
    buf.contents.should == 'abc'
  end

  it 'should be able to append raw data' do
		buf = Qrack::Transport::Buffer.new
    buf << 'abc'
    buf << 'def'
    buf.contents.should == 'abcdef'
  end

  it 'should be able to append other buffers' do
		buf = Qrack::Transport::Buffer.new
    buf << Qrack::Transport::Buffer.new('abc')
    buf.data.should == 'abc'
  end

  it 'should maintain a position pointer' do
		buf = Qrack::Transport::Buffer.new
    buf.pos.should == 0
  end

  it 'should have a length' do
		buf = Qrack::Transport::Buffer.new
    buf.length.should == 0
    buf << 'abc'
    buf.length.should == 3
  end

  it 'should know when it is empty' do
		buf = Qrack::Transport::Buffer.new
    buf.empty?.should == true
  end

  it 'should be able to read and write data' do
		buf = Qrack::Transport::Buffer.new
    buf._write('abc')
    buf.rewind
    buf._read(2).should == 'ab'
    buf._read(1).should == 'c'
  end

	it 'should raise an overflow error if trying to read when empty' do
		buf = Qrack::Transport::Buffer.new
    lambda{ buf._read(1) }.should raise_error(Qrack::BufferOverflowError)
  end

  it 'should raise an invalid type error if invalid data types used' do
		buf = Qrack::Transport::Buffer.new
    lambda{ buf.read(:junk) }.should raise_error(Qrack::InvalidTypeError)
    lambda{ buf.write(:junk, 1) }.should raise_error(Qrack::InvalidTypeError)
  end

  it "should be able to read and write various data types" do
		buf = Qrack::Transport::Buffer.new

		{ :octet => 0b10101010,
		  :short => 100,
		  :long => 100_000_000,
		  :longlong => 666_555_444_333_222_111,
		  :shortstr => 'hello',
		  :longstr => 'bye'*500,
		  :timestamp => time = Time.at(Time.now.to_i),
		  :table => { :this => 'is', :a => 'hash', :with => {:nested => 123, :and => time, :also => 123.456} },
		  :bit => true
		 }.each do |type, value|
		  buf.write(type, value)
		  buf.rewind
		  buf.read(type).should == value
		  buf.empty?.should == true
		end
		
  end

  it 'should be able to read and write multiple bits' do
		buf = Qrack::Transport::Buffer.new	
    bits = [true, false, false, true, true, false, false, true, true, false]

    buf.write(:bit, bits)
    buf.write(:octet, 100)
    
    buf.rewind
    
    bits.map do
      buf.read(:bit)
    end.should == bits

    buf.read(:octet).should == 100
  end

  it 'should be able to read and write properties' do
		buf = Qrack::Transport::Buffer.new
    properties = ([
      [:octet, 1],
      [:shortstr, 'abc'],
      [:bit, true],
      [:bit, false],
      [:shortstr, nil],
      [:timestamp, nil],
      [:table, { :a => 'hash' }],
    ]*5).sort_by{rand}
    
    buf.write(:properties, properties)
    buf.rewind
    buf.read(:properties, *properties.map{|type,_| type }).should == properties.map{|_,value| value }
    buf.empty?.should == true
  end

  it 'should be able to do transactional reads with #extract' do
		buf = Qrack::Transport::Buffer.new
		
    buf.write :octet, 8
    orig = buf.to_s

    buf.rewind
    buf.extract do |b|
      b.read :octet
      b.read :short
    end

    buf.pos.should == 0
    buf.data.should == orig
  end
	
end