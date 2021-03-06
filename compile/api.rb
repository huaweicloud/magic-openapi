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

class Api
  attr_reader :uri

  def initialize(api, uri)
    @api = api
    # remove '\'
    uri[0] = ''
    @uri = uri
  end

  def get_resource_name
    req_body = @api['create'].body_schema
    if req_body.include? 'x-resource'
      req_body['x-resource']
    else
      ''
    end
  end

  def get_description
    raw = @api['create'].raw
    if raw.include? 'description'
      raw['description']
    else
      ''
    end
  end

  def _get_api_msg_prefix(api)
	if api.nil?
	  return ''
	end
    resp_body = api.response_body_schema(200)
	if resp_body['required'].nil?
	  return ''
	end
	resp_body['required'].at(0)
  end

  def get_msg_prefix
	output = []
	apis = ['create', 'update', 'get', 'list']
	apis.each do |api|
      msg_prefix = _get_api_msg_prefix(@api[api])
	  if not msg_prefix.empty?
		msg_prefix = api + ": '" + msg_prefix + "'"
	    output.push(msg_prefix)
	  end
	end
    output
  end

  def _replace_properties(props, value, key)
    value['properties'].each do |subkey, subvalue|
      if subkey == 'replace_name' and not subvalue['title'].nil?
        props[subvalue['title']] = props[key]
        props[subvalue['title']]['field'] = key
        props.delete(key)
	  elsif subkey == 'replace_description' and not subvalue['title'].nil?
        props[key]['description'] = subvalue['title']
	  elsif not subvalue['properties'].nil?
		props[key]['properties'] = _replace_properties(props[key]['properties'], subvalue, subkey)
      end
	end
	props
  end

  def _get_properties(props, override)
    override['properties'].each do |key, value|
      if props.include? key
	    if not value['items'].nil?
		  #TODO: Add more nested properties support, if needed?
		  value['items']['properties'].each do |subkey, subvalue|
            if props[key]['items']['properties'].include? subkey
	          props[key]['items']['properties'] = _replace_properties(props[key]['items']['properties'], subvalue, subkey)
			end
		  end
		else
		  props = _replace_properties(props, value, key)
	    end
	  end
    end
	props
  end

  def _get_response_properties(api)
    resp_body = @api[api].response_body_schema(200)
	key = resp_body['required'].at(0)
    props = resp_body['properties'][key]['properties']
  end

  # This will overrides the original properties.
  def get_properties
    props = _get_response_properties('get')
    # get overrides
	if not @api['override'].nil?
      override = @api['override'].body_schema
      if not override.nil? and not override['properties'].nil?
		props = _get_properties(props, override)
      end
	end
    props
  end

  def get_required
    req_body = @api['create'].body_schema
    if req_body.include? 'required'
      req_body['required']
    else
      []
    end
  end

  def get_output
    output = []
    req_body = @api['create'].body_schema
    props = _get_response_properties('get')
    props.each do |key, value|
      if not req_body['properties'].include?(key)
        output.push(key)
      end
    end
    output
  end

  def _combine_properties(api1, api2)
    body1 = @api[api1].body_schema
    body2 = @api[api2].body_schema
	p1 = body1['properties']
	p2 = body2['properties']
	p2.each do |key, value|
	  if not p1.include?(key)
		p1[key] = value
	  end
	end
	p1
  end

  # This will overrides the original properties.
  def get_parameters
	req_props =_combine_properties('create', 'update')
    props = _get_response_properties('get')
    parameters = Hash.new
    req_props.each do |key, value|
      if not props.include?(key)
        parameters[key] = value
      end
    end

    # get overrides and handle it
	if not @api['override'].nil?
      override = @api['override'].body_schema
      if not override.nil? and not override['properties'].nil?
		parameters = _get_properties(parameters, override)
      end
	end
    parameters
  end

  def get_create_update
    create_body = @api['create'].body_schema
    create_update = Hash.new
    create_body['properties'].each do |key, value|
      if @api['update'].nil?
        create_update[key] = 'c'
      else
	    update_body = @api['update'].body_schema
        if not update_body['properties'].include?(key)
          create_update[key] = 'c'
        else
          create_update[key] = 'cu'
        end
      end
    end
    if not @api['update'].nil?
      update_body = @api['update'].body_schema
      update_body['properties'].each do |key, value|
        if not create_body['properties'].include?(key)
          create_update[key] = 'u'
        end
      end
    end
    create_update
  end

end
