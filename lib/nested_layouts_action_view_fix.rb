
class ActionView::Base
  alias_method :render_without_nested_layouts, :render 
  alias_method :_render_without_nested_layouts, :_render_with_layout

  ## Temporary for debugging
  # def render(options = {}, local_assigns = {}, &block) #:nodoc:
  #   local_assigns ||= {}
  # 
  #   case options
  #   when Hash
  #     options = options.reverse_merge(:locals => {})
  #     if layout = options[:layout]
  #       _render_with_layout(options,local_assigns, &block)
  #     elsif options[:file]
  #       template = self.view_paths.find_template(options[:file], template_format)
  #       template.render_template(self, options[:locals])
  #     elsif options[:partial]
  #       render_partial(options)
  #     elsif options[:inline]
  #       InlineTemplate.new(options[:inline], options[:type]).render(self, options[:locals])
  #     elsif options[:text]
  #       options[:text]
  #     end
  #   when :update
  #     update_page(&block)
  #   else
  #     render_partial(:partial => options, :locals => local_assigns)
  #   end
  # end

  ## Temporary for debugging
  # def render_partial(view, object = nil, local_assigns = {}, as = nil)
  #   object ||= local_assigns[:object] || local_assigns[variable_name]
  # 
  #   if object.nil? && view.respond_to?(:controller)
  #     ivar = :"@#{variable_name}"
  #     object =
  #     if view.controller.instance_variable_defined?(ivar)
  #       ActiveSupport::Deprecation::DeprecatedObjectProxy.new(
  #       view.controller.instance_variable_get(ivar),
  #       "#{ivar} will no longer be implicitly assigned to #{variable_name}")
  #     end
  #   end
  # 
  #   # Ensure correct object is reassigned to other accessors
  #   local_assigns[:object] = local_assigns[variable_name] = object
  #   local_assigns[as] = object if as
  # 
  #   render_template(view, local_assigns)
  # end

  private

  ## Temporary for debugging
  def _render_with_layout(options, local_assigns, &block) #:nodoc:
    ## Get layouts and main layout
    layouts = options.delete(:layout)
    partial_layout = layouts.delete_at(0)

    if block_given?
      begin
        @_proc_for_layout = block
        concat(render(options.merge(:partial => partial_layout)))
      ensure
        @_proc_for_layout = nil
      end
    else
      begin
        original_content_for_layout = @content_for_layout if defined?(@content_for_layout)
        @content_for_layout = render(options)
        if (options[:inline] || options[:file] || options[:text])
          @cached_content_for_layout = @content_for_layout
          ## Iterate throught nested layouts and render
          layouts.reverse.each do |layout|
            @cached_content_for_layout = @content_for_layout = render(:file => layout, :locals => local_assigns)
          end
          ## Render main layout
          render(:file => partial_layout, :locals => local_assigns)
        else
          render(options.merge(:partial => partial_layout))
        end
      ensure
        @content_for_layout = original_content_for_layout
      end
    end
  end

end


## Temporary for debugging
# class ActionView::Template
# 
#   def render(view, local_assigns = {})
#     compile(local_assigns)
# 
#     view.with_template self do
#       view.send(:_evaluate_assigns_and_ivars)
#       view.send(:_set_controller_content_type, mime_type) if respond_to?(:mime_type)
# 
#       view.send(method_name(local_assigns), local_assigns) do |*names|
#         ivar = :@_proc_for_layout
#         if !view.instance_variable_defined?(:"@content_for_#{names.first}") && view.instance_variable_defined?(ivar) && (proc = view.instance_variable_get(ivar))
#           view.capture(*names, &proc)
#         elsif view.instance_variable_defined?(ivar = :"@content_for_#{names.first || :layout}")
#           view.instance_variable_get(ivar)
#         end
#       end
#     end
#   end
# 
#   def render_template(view, local_assigns = {})
#     render(view, local_assigns)
#   rescue Exception => e
#     raise e unless filename
#     if TemplateError === e
#       e.sub_template_of(self)
#       raise e
#     else
#       raise TemplateError.new(self, view.assigns, e)
#     end
#   end
# 
# end