require "ice_cube"
require_relative "utilities/form_options_ext"
require_relative "utilities/tag_ext"

module RecurringSelectHelper
  module FormHelper
    def select_recurring(object, method, default_schedules = nil, options = {}, html_options = {})
      if Rails::VERSION::STRING.to_f >= 4.0
        # === Rails 4
        RecurringSelectTag.new(object, method, self, default_schedules, options, html_options).render
      else
        # === Rails 3
        InstanceTag.new(object, method, self, options.delete(:object)).to_recurring_select_tag(default_schedules, options, html_options)
      end
    end
  end

  module FormOptionsHelper
    def recurring_options_for_select(currently_selected_rule = nil, default_schedules = nil, options = {})

      options_array = []
      blank_option_label = options[:blank_label] || "- not recurring -"
      blank_option = [blank_option_label, "null"]
      seperator = ["or", {:disabled => true}]

      if default_schedules.blank?
        if currently_selected_rule
          options_array << blank_option if options[:allow_blank]
          options_array << ice_cube_rule_to_option(currently_selected_rule)
          options_array << seperator
          options_array << ["Change schedule...", "custom"]
        else
          options_array << blank_option
          options_array << ["Set schedule...", "custom"]
        end
	  end
    end

    def current_rule_in_defaults?(currently_selected_rule, default_schedules)
      default_schedules.any?{|option|
        option == currently_selected_rule or
          (option.is_a?(Array) and option[1] == currently_selected_rule)
      }
    end
  end

  class RecurringSelectTag < ActionView::Helpers::Tags::Base
    include FormOptionsHelper

    def initialize(object, method, template_object, default_schedules = nil, options = {}, html_options = {})
      @default_schedules = default_schedules
      @choices = @choices.to_a if @choices.is_a?(Range)
      @method_name = method.to_s
      @object_name = object.to_s
      @html_options = recurring_select_html_options(html_options)
      add_default_name_and_id(@html_options)

      super(object, method, template_object, options)
    end

    def render
      option_tags = add_options(recurring_options_for_select(value(object), @default_schedules, @options), @options, value(object))
      select_content_tag(option_tags, @options, @html_options)
    end

    private

    def recurring_select_html_options(html_options)
      html_options = html_options.stringify_keys
      html_options["class"] = ((html_options["class"] || "").split() + ["recurring_select"]).join(" ")
      html_options
    end
  end

  module FormBuilder
    def select_recurring(method, default_schedules = nil, options = {}, html_options = {})
      if !@template.respond_to?(:select_recurring)
        @template.class.send(:include, RecurringSelectHelper::FormHelper)
      end

      @template.select_recurring(@object_name, method, default_schedules, options.merge(:object => @object), html_options)
    end
  end
end
