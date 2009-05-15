require 'rexml/document'
require 'erb'
require 'pathname'
require 'yaml'

include REXML

class InputError < StandardError; end

def spec_details(doc)
  # AMQP spec details
  
  spec_details = {}

  root = doc.root
  spec_details['major'] = root.attributes["major"]
  spec_details['minor'] = root.attributes["minor"]
  spec_details['revision'] = root.attributes["revision"] || '0'
  spec_details['port'] = root.attributes["port"]
  spec_details['comment'] = root.attributes["comment"] || 'No comment'
  
  spec_details
end

def process_constants(doc)
  # AMQP constants
  
  frame_constants = {}
  other_constants = {}

  doc.elements.each("amqp/constant") do |element|
    if element.attributes["name"].match(/^frame/)
      frame_constants[element.attributes["value"].to_i] = 
      element.attributes["name"].sub(/^frame./,'').split(/\s|-/).map{|w| w.downcase.capitalize}.join
    else
      other_constants[element.attributes["value"]] = element.attributes["name"]
    end
  end
  
  [frame_constants.sort, other_constants.sort]
end

def domain_types(doc, major, minor, revision)
  # AMQP domain types

  dt_arr = []
  doc.elements.each("amqp/domain") do |element|
     dt_arr << element.attributes["type"]
  end
  
  # Add domain types for specific document
  add_arr = add_types(major, minor, revision)
  type_arr = dt_arr + add_arr

  # Return sorted array
  type_arr.uniq.sort
end

def classes(doc, major, minor, revision)
  # AMQP classes

  cls_arr = []
  
  doc.elements.each("amqp/class") do |element|
    cls_hash = {}
    cls_hash[:name] = element.attributes["name"]
    cls_hash[:index] = element.attributes["index"]
    # Get fields for class
    field_arr = fields(doc, element)
    cls_hash[:fields] = field_arr
    # Get methods for class
    meth_arr = class_methods(doc, element)
    # Add missing methods
    add_arr =[]
    add_arr = add_methods(major, minor, revision) if cls_hash[:name] == 'queue'
    method_arr = meth_arr + add_arr
    # Add array to class hash
    cls_hash[:methods] = method_arr
    cls_arr << cls_hash
  end
  
  # Return class information array
  cls_arr
end

def class_methods(doc, cls)
  meth_arr = []
  
  # Get methods for class
  cls.elements.each("method") do |method|
    meth_hash = {}
    meth_hash[:name] = method.attributes["name"]
    meth_hash[:index] = method.attributes["index"]
    # Get fields for method
    field_arr = fields(doc, method)
    meth_hash[:fields] = field_arr
    meth_arr << meth_hash
  end
  
  # Return methods
  meth_arr
end

def fields(doc, element)
  field_arr = []
  
  # Get fields for element
  element.elements.each("field") do |field|
    field_hash = {}
    field_hash[:name] = field.attributes["name"].tr(' ', '-')
    field_hash[:domain] = field.attributes["type"] || field.attributes["domain"]

    # Convert domain type if necessary
    conv_arr = convert_type(field_hash[:domain])
    field_hash[:domain] = conv_arr[0][1] unless conv_arr.empty?
    
    field_arr << field_hash
  end
  
  #  Return fields
  field_arr
  
end

def add_types(major, minor, revision)
  type_arr = []
  type_arr = ['long', 'longstr', 'octet', 'timestamp'] if (major == '8' and minor == '0' and revision == '0')
  type_arr
end

def add_methods(major, minor, revision)
  meth_arr = []
  
  if (major == '8' and minor == '0' and revision == '0')
    # Add Queue Unbind method
    meth_hash = {:name => 'unbind',
                 :index => '50',
                 :fields => [{:name => 'ticket', :domain => 'short'},
                             {:name => 'queue', :domain => 'shortstr'},   
                             {:name => 'exchange', :domain => 'shortstr'},   
                             {:name => 'routing_key', :domain => 'shortstr'},   
                             {:name => 'arguments', :domain => 'table'}
                            ]
                }
                
    meth_arr << meth_hash
    
    # Add Queue Unbind-ok method
    meth_hash = {:name => 'unbind-ok',
                 :index => '51',
                 :fields => []
                }
                
    meth_arr << meth_hash
  end
  
  # Return methods
  meth_arr
  
end

def convert_type(name)
  type_arr = @type_conversion.select {|k,v| k == name}
end

# Start of Main program

# Read in config options
CONFIG = YAML::load(File.read('config.yml'))

# Get path to the spec file and the spec file name on its own
specpath = CONFIG[:spec_in]
path = Pathname.new(specpath)
specfile = path.basename.to_s

# Read in the spec file
doc = Document.new(File.new(specpath))

# Declare type conversion hash
@type_conversion = {'path' => 'shortstr',
                    'known hosts' => 'shortstr',
                    'known-hosts' => 'shortstr',
                    'reply code' => 'short',
                    'reply-code' => 'short',
                    'reply text' => 'shortstr',
                    'reply-text' => 'shortstr',
                    'class id' => 'short',
                    'class-id' => 'short',
                    'method id' => 'short',
                    'method-id' => 'short',
                    'channel-id' => 'longstr',
                    'access ticket' => 'short',
                    'access-ticket' => 'short',
                    'exchange name' => 'shortstr',
                    'exchange-name' => 'shortstr',
                    'queue name' => 'shortstr',
                    'queue-name' => 'shortstr',
                    'consumer tag' => 'shortstr',
                    'consumer-tag' => 'shortstr',
                    'delivery tag' => 'longlong',
                    'delivery-tag' => 'longlong',
                    'redelivered' => 'bit',
                    'no ack' => 'bit',
                    'no-ack' => 'bit',
                    'no local' => 'bit',
                    'no-local' => 'bit',
                    'peer properties' => 'table',
                    'peer-properties' => 'table',
                    'destination' => 'shortstr',
                    'duration' => 'longlong',
                    'security-token' => 'longstr',
                    'reject-code' => 'short',
                    'reject-text' => 'shortstr',
                    'offset' => 'longlong',
                    'no-wait' => 'bit',
                    'message-count' => 'long'
                   }
        
# Spec details
spec_info = spec_details(doc)

# Constants
constants = process_constants(doc)

# Frame constants
frame_constants = constants[0].select {|k,v| k <= 8}
frame_footer = constants[0].select {|k,v| v == 'End'}[0][0]

# Other constants
other_constants = constants[1]

# Domain types
data_types = domain_types(doc, spec_info['major'], spec_info['minor'], spec_info['revision'])

# Classes
class_defs = classes(doc, spec_info['major'], spec_info['minor'], spec_info['revision'])

# Generate spec.rb
spec_rb = File.open(CONFIG[:spec_out], 'w')
spec_rb.puts(
ERB.new(%q[
  #:stopdoc:
  # this file was autogenerated on <%= Time.now.to_s %>
  # using <%= specfile.ljust(16) %> (mtime: <%= File.mtime(specpath) %>)
  #
  # DO NOT EDIT! (edit ext/qparser.rb and config.yml instead, and run 'ruby qparser.rb')

  module Qrack
    module Protocol
      HEADER        = "AMQP".freeze
      VERSION_MAJOR = <%= spec_info['major'] %>
      VERSION_MINOR = <%= spec_info['minor'] %>
      REVISION      = <%= spec_info['revision'] %>
      PORT          = <%= spec_info['port'] %>

      RESPONSES = {
        <%- other_constants.each do |value, name| -%>
        <%= value %> => :<%= name.gsub(/\s|-/, '_').upcase -%>,
        <%- end -%>
      }

      FIELDS = [
        <%- data_types.each do |d| -%>
        :<%= d -%>,
        <%- end -%>
      ]

      class Class
        class << self
          FIELDS.each do |f|
            class_eval %[
              def #{f} name
                properties << [ :#{f}, name ] unless properties.include?([:#{f}, name])
                attr_accessor name
              end
            ]
          end

          def properties() @properties ||= [] end

          def id()   self::ID end
          def name() self::NAME end
        end

        class Method
          class << self
            FIELDS.each do |f|
              class_eval %[
                def #{f} name
                  arguments << [ :#{f}, name ] unless arguments.include?([:#{f}, name])
                  attr_accessor name
                end
              ]
            end

            def arguments() @arguments ||= [] end

            def parent() Protocol.const_get(self.to_s[/Protocol::(.+?)::/,1]) end
            def id()     self::ID end
            def name()   self::NAME end
          end

          def == b
            self.class.arguments.inject(true) do |eql, (type, name)|
              eql and __send__("#{name}") == b.__send__("#{name}")
            end
          end
        end

        def self.methods() @methods ||= {} end

        def self.Method(id, name)
          @_base_methods ||= {}
          @_base_methods[id] ||= ::Class.new(Method) do
            class_eval %[
              def self.inherited klass
                klass.const_set(:ID, #{id})
                klass.const_set(:NAME, :#{name.to_s})
                klass.parent.methods[#{id}] = klass
                klass.parent.methods[klass::NAME] = klass
              end
            ]
          end
        end
      end

      def self.classes() @classes ||= {} end

      def self.Class(id, name)
        @_base_classes ||= {}
        @_base_classes[id] ||= ::Class.new(Class) do
          class_eval %[
            def self.inherited klass
              klass.const_set(:ID, #{id})
              klass.const_set(:NAME, :#{name.to_s})
              Protocol.classes[#{id}] = klass
              Protocol.classes[klass::NAME] = klass
            end
          ]
        end
      end
    end
  end

  module Qrack
    module Protocol
      <%- class_defs.each do |h| -%>
      class <%= h[:name].capitalize.ljust(12) %> < Class( <%= h[:index].to_s.rjust(3) %>, :<%= h[:name].ljust(12) %> ); end
      <%- end -%>

      <%- class_defs.each do |c| -%>
      class <%= c[:name].capitalize %>
        <%- c[:fields].each do |p| -%>
        <%= p[:domain].ljust(10) %> :<%= p[:name].tr('-','_') %>
        <%- end if c[:fields] -%>

        <%- c[:methods].each do |m| -%>
        class <%= m[:name].capitalize.gsub(/-(.)/){ "#{$1.upcase}"}.ljust(12) %> < Method( <%= m[:index].to_s.rjust(3) %>, :<%= m[:name].tr('- ','_').ljust(14) %> ); end
        <%- end -%>

        <%- c[:methods].each do |m| -%>

        class <%= m[:name].capitalize.gsub(/-(.)/){ "#{$1.upcase}"} %>
          <%- m[:fields].each do |a| -%>
          <%- if a[:domain] -%>
          <%= a[:domain].ljust(16) %> :<%= a[:name].tr('- ','_') %>
          <%- end -%>
          <%- end -%>
        end
        <%- end -%>

      end

      <%- end -%>
    end

  end
].gsub!(/^  /,''), nil, '>-%').result(binding)
)

# Close spec.rb file
spec_rb.close

# Generate frame.rb file

frame_rb = File.open(CONFIG[:frame_out], 'w')
frame_rb.puts(
ERB.new(%q[
  #:stopdoc:
  # this file was autogenerated on <%= Time.now.to_s %>
  #
  # DO NOT EDIT! (edit ext/qparser.rb and config.yml instead, and run 'ruby qparser.rb')

  module Qrack
    module Transport
      class Frame
        def self.types
          @types ||= {}
        end

        def self.Frame id
          (@_base_frames ||= {})[id] ||= Class.new(Frame) do
            class_eval %[
              def self.inherited klass
                klass.const_set(:ID, #{id})
                Frame.types[#{id}] = klass
              end
            ]
          end
        end

        <%- frame_constants.each do |value, name| -%>
        class <%= name.ljust(9) -%> < Frame( <%= value.to_s -%> ); end
        <%- end -%>

        FOOTER = <%= frame_footer %>
      end
    end
  end

  module Qrack
    module Transport
      class Frame
        def initialize payload = nil, channel = 0
          @channel, @payload = channel, payload
        end
        attr_accessor :channel, :payload

        def id
          self.class::ID
        end
    
        def to_binary
          buf = Transport::Buffer.new
          buf.write :octet, id
          buf.write :short, channel
          buf.write :longstr, payload
          buf.write :octet, Transport::Frame::FOOTER
          buf.rewind
          buf
        end

        def to_s
          to_binary.to_s
        end

        def == frame
          [ :id, :channel, :payload ].inject(true) do |eql, field|
            eql and __send__(field) == frame.__send__(field)
          end
        end
    
        class Method
          def initialize payload = nil, channel = 0
            super
            unless @payload.is_a? Protocol::Class::Method or @payload.nil?
              @payload = Protocol.parse(@payload)
            end
          end
        end

        class Header
          def initialize payload = nil, channel = 0
            super
            unless @payload.is_a? Protocol::Header or @payload.nil?
              @payload = Protocol::Header.new(@payload)
            end
          end
        end

        class Body; end

        def self.parse buf
          buf = Transport::Buffer.new(buf) unless buf.is_a? Transport::Buffer
          buf.extract do
            id, channel, payload, footer = buf.read(:octet, :short, :longstr, :octet)
            Transport::Frame.types[id].new(payload, channel) if footer == Transport::Frame::FOOTER
          end
        end
      end
    end
  end
  ].gsub!(/^  /,''), nil, '>-%').result(binding)
  )

  # Close frame.rb file
  frame_rb.close