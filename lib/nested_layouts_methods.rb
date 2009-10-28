module MyMod
  module ActionController
    module Base

      def self.included(base) 
        base.extend NestedLayouts::ClassMethods
        # base.send(:include, NestedLayouts::InstanceMethods)
      end 

      module NestedLayouts

        # module InstanceMethods
        # 
        # end

        module ClassMethods
          ## Methods for setting Nested layouts 
          def next_layouts(new_layouts, conditions = {}, auto = false)
            self.layout(([read_inheritable_attribute(:layout)] + [new_layouts]).flatten.compact, conditions, auto)
          end

          def layouts(layouts, conditions = {}, auto = false)
            self.layout(layouts, conditions, auto)
          end

          def layout(template_name, conditions = {}, auto = false)
            add_layout_conditions(conditions)
            write_inheritable_attribute(:layout, [template_name].flatten.compact)
            write_inheritable_attribute(:auto_layout, auto)
          end

          def nested_layouts(layouts, conditions = {}, auto = false)
            self.layout(layouts, conditions, auto)
          end

        end
      end

    end
  end
end