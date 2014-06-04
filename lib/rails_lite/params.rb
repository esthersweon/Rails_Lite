require 'uri'

class Params

  def initialize(req, route_params = {})
    @params = {}

  # params from query string
    if req.query_string
      @params.merge!(parse_www_encoded_form(req.query_string))
    end
  
  # params from post body
    if req.body
      @params.merge!(parse_www_encoded_form(req.body))
    end

  # params from route params
    @params.merge!(route_params)

    @permitted = []

  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    @permitted.push *keys
  end

  def require(key)
    raise AttributeNotFoundError unless @params.has_key?(key)
    @params[key]
  end

  def permitted?(key)
    @permitted.include?(key)
  end

  def to_s
    @params.to_json.to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    params = {}

    keys_values = URI.decode_www_form(www_encoded_form)
    keys_values.each do |unparsed_key, value|
      scope = params
      
      all_keys = parse_key(unparsed_key)

      all_keys.each_with_index do |key, index|
        if index == (all_keys.count - 1)
          scope[key] = value
        else
          scope[key] ||= {}
          scope = scope[key]
        end
      end
    end

    params
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.split(/\[|\]\[|\]/)
  end
end
