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

require 'erb'
require 'compile/api'

class Compiler
  include ERB::Util

  def initialize(openapi, template, uris, overrides)
    @openapi = openapi
    @template = template
    @uris = uris
    @overrides = overrides
  end

  def get_apis
    apis = []
    @uris.each do |uri|
      api = Hash.new
      api['post'] = @openapi.endpoint(uri, 'post')
      api['get'] = @openapi.endpoint(uri+'/1', 'get')
      api['put'] = @openapi.endpoint(uri+'/1', 'put')
	  if not @overrides.nil?
        api['override'] = @overrides.endpoint(uri, 'post')
	  else
		api['override'] = nil
      end
      if not api['post'].nil? and not api['get'].nil?
        apis.push(Api.new(api, uri))
      end
    end
    apis
  end

  def compile_file(ctx, source)
    ERB.new(File.read(source), nil, '-%>').result(ctx).split("\n")
  rescue StandardError => e
    puts "Error compiling file: #{source}"
    raise e
  end

  def lines(code, number = 0)
    return if code.nil? || code.empty?
    code = code.join("\n") if code.is_a?(Array)
    code[-1] = '' while code[-1] == "\n" || code[-1] == "\r"
    "#{code}#{"\n" * (number + 1)}"
  end

  def compile_template(template_file, data)
    ctx = binding
    data.each { |name, value| ctx.local_variable_set(name, value) }
    compile_file(ctx, template_file).join("\n")
  end

  def build_object_resource(object)
    compile_template(
      'templates/resource.erb',
      required: object.get_required,
      output: object.get_output,
      cu: object.get_create_update,
      resource_name: object.get_resource_name,
      description: object.get_description,
      msg_prefix: object.get_msg_prefix,
      parameters: object.get_parameters,
      properties: object.get_properties,
      base_url: object.uri
    )
  end

  def build_object_property(props, required, output, cu)
    compile_template(
      'templates/property.erb',
      props: props,
      required: required,
      output: output,
      cu: cu
    )
  end

  def build_nested_object_property(props)
    compile_template(
      'templates/nested_property.erb',
      props: props,
    )
  end

  def build_nested_nested_object_property(props)
    compile_template(
      'templates/nested_nested_property.erb',
      props: props,
    )
  end

  def render()
    apis = get_apis
    ERB.new(File.read(@template), nil, '-%>').result(binding)
  end

  def generate(output)
    file = File.join(output, 'api.yaml')
    File.open(file, "w+") do |f|
      f.write(render)
    end
  end

end
