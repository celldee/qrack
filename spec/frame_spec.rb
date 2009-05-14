# frame_spec.rb

require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib qrack]))

describe Qrack::Transport::Frame do
	
	it 'should handle basic frame types' do
    Qrack::Transport::Frame::Method.new.id.should == 1
    Qrack::Transport::Frame::Header.new.id.should == 2
    Qrack::Transport::Frame::Body.new.id.should == 3
  end

  it 'should be able to convert method frames to binary' do
    meth = Qrack::Protocol::Connection::Secure.new :challenge => 'secret'

    frame = Qrack::Transport::Frame::Method.new(meth)
    frame.to_binary.should be_an_instance_of Qrack::Transport::Buffer
    frame.to_s.should == [ 1, 0, meth.to_s.length, meth.to_s, 206 ].pack('CnNa*C')
  end

  it 'should be able to convert binary to method frames' do
    orig = Qrack::Transport::Frame::Method.new(Qrack::Protocol::Connection::Secure.new(:challenge => 'secret'))
    copy = Qrack::Transport::Frame.parse(orig.to_binary)
    copy.should == orig
  end

  it 'should ignore partial frames until complete' do
    frame = Qrack::Transport::Frame::Method.new(Qrack::Protocol::Connection::Secure.new(:challenge => 'secret'))
    data = frame.to_s

    buf = Qrack::Transport::Buffer.new
    Qrack::Transport::Frame.parse(buf).should == nil
    
    buf << data[0..5]
    Qrack::Transport::Frame.parse(buf).should == nil
    
    buf << data[6..-1]
    Qrack::Transport::Frame.parse(buf).should == frame
    
    Qrack::Transport::Frame.parse(buf).should == nil
  end

  it 'should be able to convert header frames to binary' do
    head = Qrack::Protocol::Header.new(Qrack::Protocol::Basic, :priority => 1)
    
    frame = Qrack::Transport::Frame::Header.new(head)
    frame.to_s.should == [ 2, 0, head.to_s.length, head.to_s, 206 ].pack('CnNa*C')
  end

  it 'should be able to convert binary to header frame' do
    orig = Qrack::Transport::Frame::Header.new(Qrack::Protocol::Header.new(Qrack::Protocol::Basic, :priority => 1))
    
    copy = Qrack::Transport::Frame.parse(orig.to_binary)
    copy.should == orig
  end
	
end