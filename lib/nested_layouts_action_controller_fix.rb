
class ActionController::Base #:nodoc:
  alias_method :render_without_nested_layouts, :render 

  protected

  def render(options = nil, extra_options = {}, &block)
    raise DoubleRenderError, "Can only render or redirect once per action" if performed?
    validate_render_arguments(options, extra_options, block_given?)

    if options.nil?
      options = { :template => default_template, :layout => true }
    elsif options == :update
      options = extra_options.merge({ :update => true })
    elsif options.is_a?(String) || options.is_a?(Symbol)
      case options.to_s.index('/')
      when 0
        extra_options[:file] = options
      when nil
        extra_options[:action] = options
      else
        extra_options[:template] = options
      end

      options = extra_options
    elsif !options.is_a?(Hash)
      extra_options[:partial] = options
      options = extra_options
      options[:layout] = options[:layouts] if options[:layouts] and not options[:layout] 
    end


    layout = pick_layout(options)
    ## There is just one change, that will iterate layout array and log their names
    # response.layout = layout.path_without_format_and_extension if layout
    layout.each do |l|
      logger.info("Rendering template within #{l.path_without_format_and_extension}")
    end if logger and layout.is_a?(Array)

    if content_type = options[:content_type]
      response.content_type = content_type.to_s
    end

    if location = options[:location]
      response.headers["Location"] = url_for(location)
    end

    if options.has_key?(:text)
      text = layout ? @template.render(options.merge(:text => options[:text], :layout => layout)) : options[:text]
      render_for_text(text, options[:status])

    else
      if file = options[:file]
        render_for_file(file, options[:status], layout, options[:locals] || {})

      elsif template = options[:template]
        render_for_file(template, options[:status], layout, options[:locals] || {})

      elsif inline = options[:inline]
        render_for_text(@template.render(options.merge(:layout => layout)), options[:status])

      elsif action_name = options[:action]
        render_for_file(default_template(action_name.to_s), options[:status], layout)

      elsif xml = options[:xml]
        response.content_type ||= Mime::XML
        render_for_text(xml.respond_to?(:to_xml) ? xml.to_xml : xml, options[:status])

      elsif js = options[:js]
        response.content_type ||= Mime::JS
        render_for_text(js, options[:status])

      elsif options.include?(:json)
        json = options[:json]
        json = ActiveSupport::JSON.encode(json) unless json.is_a?(String)
        json = "#{options[:callback]}(#{json})" unless options[:callback].blank?
        response.content_type ||= Mime::JSON
        render_for_text(json, options[:status])

      elsif options[:partial]
        options[:partial] = default_template_name if options[:partial] == true
        if layout
          render_for_text(@template.render(:text => @template.render(options), :layout => layout), options[:status])
        else
          render_for_text(@template.render(options), options[:status])
        end

      elsif options[:update]
        @template.send(:_evaluate_assigns_and_ivars)

        generator = ActionView::Helpers::PrototypeHelper::JavaScriptGenerator.new(@template, &block)
        response.content_type = Mime::JS
        render_for_text(generator.to_s, options[:status])

      elsif options[:nothing]
        render_for_text(nil, options[:status])

      else
        render_for_file(default_template, options[:status], layout)
      end
    end
  end

  def active_layout(passed_layouts = nil, options = {})
    layouts = passed_layouts || default_layout
    layouts = [layouts].flatten
    return layouts if not layouts.collect {|l| l.respond_to?(:render)}.include?(false)

    active_layouts = layouts.collect! do |layout|
      case layout
      when Symbol then __send__(layout)
      when Proc   then layout.call(self)
      else layout
      end
    end

    active_layouts.collect do |active_layout|
      find_layout(active_layout, default_template_format, options[:html_fallback])
    end
  end

  private
  ## Temporary for debugging
  def default_layout #:nodoc:
    layout = self.class.read_inheritable_attribute(:layout)
    return layout unless self.class.read_inheritable_attribute(:auto_layout)
    find_layout(layout, default_template_format)
  rescue ActionView::MissingTemplate
    nil
  end

  ## Create inteligent searching of layouts
  def find_layout(layout, format, html_fallback=false) #:nodocs:
    view_paths.find_template(layout, format, html_fallback, self.class.to_s.underscore.gsub('_controller', ''))
  rescue ActionView::MissingTemplate
    raise if Mime::Type.lookup_by_extension(format.to_s).html?
  end

  ## Temporary for debugging
  def pick_layout(options)
    if options.has_key?(:layout)
      case layout = options.delete(:layout)
      when FalseClass
        nil
      when NilClass, TrueClass
        active_layout if action_has_layout? && candidate_for_layout?(:template => default_template_name)
      else
        active_layout(layout, :html_fallback => true)
      end
    else
      active_layout if action_has_layout? && candidate_for_layout?(options)
    end
  end

  ## Temporary just for debugging
  ## In future let it find layouts based on controller hierarchy.
  ## For example. CarsController will have layouts like "layouts/application, cars/cars_layout"
  # def candidate_for_layout?(options)
  #   template = options[:template] || default_template(options[:action])
  #   if options.values_at(:text, :xml, :json, :file, :inline, :partial, :nothing, :update).compact.empty?
  #     begin
  #       template_object = self.view_paths.find_template(template, default_template_format)
  #       @real_format = :html if response.template.template_format == :js && template_object.format == "html"
  #       !template_object.exempt_from_layout?
  #     rescue ActionView::MissingTemplate
  #       true
  #     end
  #   end
  # rescue ActionView::MissingTemplate
  #   false
  # end

end