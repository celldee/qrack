$: << File.expand_path(File.dirname(__FILE__))

require 'protocol/spec'
require 'protocol/protocol'

require 'transport/buffer'
require 'transport/frame'

module Qrack
	
	include Protocol
	include Transport
	
  # Qrack version number
  VERSION = '0.0.1'

  # Return the Qrack version
  def self.version
    VERSION
  end

end