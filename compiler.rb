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

uris = [
  '/os-keypairs',
]

ARGV << '-h' if ARGV.empty?

OptionParser.new do |opt|
  opt.on('-s', '--service SERVICE', 'Folder with service catalog') do |s|
    catalog = s
  end
  opt.on('-o', '--output OUTPUT', 'Folder for api output') do |o|
    output = o
  end
  opt.on('-h', '--help', 'Show this message') do
    puts opt
    exit
  end
end.parse!

raise 'Option -s/--service is a required parameter' if catalog.nil?
raise 'Option -o/--output is a required parameter' if output.nil?

raise "Service '#{catalog}' does not have api.yaml" \
  unless File.exist?(File.join(catalog, 'api.yaml'))

raise "Output '#{output}' is not a directory" unless Dir.exist?(output)

openapi = OpenApiParser::Specification.resolve(File.join(catalog, 'api.yaml'))

temp = catalog.sub('services', 'templates')
template = File.join(temp, 'api.erb')
compiler = Compiler.new(openapi, template, uris)
compiler.generate output
