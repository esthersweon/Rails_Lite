require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'


class ControllerBase
  attr_reader :params, :req, :res

  # controller set-up
  def initialize(req, res, route_params = {})
    @req = req
    @res = res

    @already_built_response = false

    @params = Params.new(req, route_params)
  end

  def render_content(content, type)
    raise "already rendered" if already_built_response?
    @res.body = content
    @res.content_type = type
    session.store_session(@res)

    @already_built_response = true

    nil
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise "already rendered for redirect" if already_built_response?
    @res.status = 302
    @res.header['location'] = url
    session.store_session(@res)
    
    @already_built_response = true

    nil
  end

  def render(template_name)
    template_file_name = 
      "views/#{self.class.name.underscore}/#{template_name}.html.erb"
    render_content(
      ERB.new(File.read(template_file_name)).result(binding), "text/html")
  end

  def session
    @session ||= Session.new(@req)
  end

  # use with router to call controller actions (:index, :show, etc.)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?

    nil
  end
  
end
