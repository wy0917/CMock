require 'erb'
require 'fileutils'
require_relative '../lib/cmock_header_parser.rb'
require_relative '../lib/cmock_config.rb'


raise 'Header file to mock must be specified!' unless ARGV.length >= 1

mock_out = ENV.fetch('MOCK_OUT', './build/test/mocks')
mock_prefix = ENV.fetch('MOCK_PREFIX', 'mock_')
header_file = ARGV[0]
base_name = File.basename(header_file, ".h")
class_name = base_name.gsub(/[_-]/, ' ').split.map(&:capitalize).join

cfg = CMockConfig.new

# Parse the header file to get the function declarations
parser = CMockHeaderParser.new(cfg)
parsed_stuff = parser.parse(class_name, File.read(header_file))

# unless parsed_stuff[:functions].nil?
#     parsed_stuff[:functions].each do |function|
#         puts "Function: #{function[:name]}"
#         puts "Return type: #{function[:return_type]}"
#         puts "Arguments: #{function[:args].join(', ')}"
#         puts "-------------------------"
#     end
# end

# parsed_stuff[:include].each do |inc|
#     puts "including #{inc}"
# end

# Generate the interface class
mock_header_template = ERB.new <<-EOF
#ifndef MOCK_<%= base_name.upcase %>_H_
#define MOCK_<%= base_name.upcase %>_H_

#include "gtest/gtest.h"
#include "gmock/gmock"

#include "<%= File.basename(header_file) %>"

class <%= class_name %>Interface {
public:
  virtual ~<%= class_name %>Interface() {}
<% parsed_stuff[:functions].each do |function| %>
  virtual <%= function[:return][:type] %> <%= function[:name] %>(<%= function[:args_string] %>) = 0;
<% end %>
};

class Mock<%= class_name %> : public <%= class_name %>Interface {
public:
<% parsed_stuff[:functions].each do |function| %>
  MOCK_METHOD(<%= function[:return][:type] %>, <%= function[:name] %>, (<%= function[:args].map { |arg| "\#{arg[:type]}"}.join(', ') %>), (override));
<% end %>
};

#endif  // MOCK_<%= base_name.upcase %>_H_
EOF

File.open("#{mock_out}/#{mock_prefix}#{base_name}.h", 'w') do |file|
  file.write(mock_header_template.result(binding))
end

# Generate the mock C file
mock_c_template = ERB.new <<-EOF
#include "mock_<%= base_name %>.h"

Mock<%= class_name %>* mock_<%= base_name %>;

<% parsed_stuff[:functions].each do |function| %>
<%= function[:return][:type] %> <%= function[:name] %>(<%= function[:args].map { |arg| "\#{arg[:type]} \#{arg[:name]}" }.join(', ') %>)
{
    return mock_<%= base_name %>-><%= function[:name] %>(<%= function[:args].map { |arg| arg[:name] }.join(', ') %>);
}
<% end %>
EOF

File.open("#{mock_out}/#{mock_prefix}#{base_name}.c", 'w') do |file|
    file.write(mock_c_template.result(binding))
end
