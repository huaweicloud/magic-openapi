#!/usr/bin/env ruby
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$LOAD_PATH.unshift File.dirname(__FILE__)

# Run from compiler dir so all references are relative to the compiler
# executable.
Dir.chdir(File.dirname(__FILE__))

require 'compile/core'
require 'open_api_parser'
require 'optparse'

catalog = nil
output = nil

ARGV << '-h' if ARGV.empty?

OptionParser.new do |opt|
  opt.on('-p', '--product PRODUCT', 'Folder with product catalog') do |p|
    catalog = p
  end
  opt.on('-o', '--output OUTPUT', 'Folder for api output') do |o|
    output = o
  end
  opt.on('-h', '--help', 'Show this message') do
    puts opt
    exit
  end
end.parse!

raise 'Option -p/--product is a required parameter' if catalog.nil?
raise 'Option -o/--output is a required parameter' if output.nil?

raise "Product '#{catalog}' does not have api.yaml" \
  unless File.exist?(File.join(catalog, 'api.yaml'))

raise "Output '#{output}' is not a directory" unless Dir.exist?(output)

api = OpenApiParser::Specification.resolve(File.join(catalog, 'api.yaml'))
#endpoint = api.endpoint('/os-keypairs', 'post')
#p endpoint.body_schema

template = 'templates/api.erb'
compiler = Compiler.new(api, template)
compiler.generate output
