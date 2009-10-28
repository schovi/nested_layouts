# Include hook code here
require 'nested_layouts_methods'
require 'nested_layouts_action_controller_fix'
require 'nested_layouts_action_view_fix'
ActionController::Base.send(:include, MyMod::ActionController::Base) 
