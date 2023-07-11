# frozen_string_literal: true

module QA
  module EE
    module Page
      module ValueStreamAnalytics
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.class_eval do
            view "ee/app/assets/javascripts/analytics/cycle_analytics/components/value_stream_empty_state.vue" do
              element :create_value_stream_button
            end

            view "ee/app/assets/javascripts/analytics/cycle_analytics/components/value_stream_form_content.vue" do
              element :value_stream_form_modal
              element :create_value_stream_name_input
              element :vsa_preset_selector
            end

            view "ee/app/assets/javascripts/analytics/cycle_analytics/components/base.vue" do
              element :vsa_path_navigation
            end

            view "app/assets/javascripts/analytics/shared/components/value_stream_metrics.vue" do
              element :vsa_metrics
            end

            view "ee/app/assets/javascripts/analytics/cycle_analytics/components/duration_chart.vue" do
              element :vsa_duration_chart
            end

            view "ee/app/assets/javascripts/analytics/cycle_analytics/components/duration_overview_chart.vue" do
              element :vsa_duration_overview_chart
            end
          end
        end

        # Create new value stream from default template
        #
        # @param [String] name
        # @return [void]
        def create_new_value_stream_from_default_template(name)
          click_element(:create_value_stream_button)
          fill_element(:create_value_stream_name_input, name)
          create_value_stream
        end

        # Create new value stream from custom template
        #
        # @param [String] name
        # @param [Array] stages
        # @return [void]
        def create_new_custom_value_stream(name, stages)
          click_element(:create_value_stream_button)
          fill_element(:create_value_stream_name_input, name)
          select_value_stream_type("blank")

          stages.each_with_index do |stage, index|
            within_element(:"custom-stage-name-#{index}") { fill_element("input[type=text]", stage[:name]) }
            select_custom_event("start", index, stage[:start_event])
            select_custom_event("end", index, stage[:end_event])
            add_another_stage unless stages.size == (index + 1)
          end

          create_value_stream
        end

        # VSA page has stages
        #
        # @param [Array<String>] stage_names
        # @return [Boolean]
        def has_stages?(stage_names)
          within_element(:vsa_path_navigation) do
            stage_names.all? { |stage_name| find_button(stage_name, wait: 5) }
          end
        end

        # VSA page lifecycle metrics container
        #
        # @param [Integer] wait
        # @return [Capybara::Node::Element]
        def lifecycle_metrics(wait: 5)
          find_element(:vsa_metrics, wait: wait)
        end

        # VSA page duration overview chart element
        #
        # @param [Integer] wait
        # @return [Capybara::Node::Element]
        def overview_chart(wait: 5)
          find_element(:vsa_duration_overview_chart, wait: wait)
        end

        # Select dates for result filtering by providing date strings in YYYY-MM-DD format
        #
        # @param [String] from
        # @param [String] to
        # @return [void]
        def select_date_range(from:, to:)
          set_date(:daterange_picker_start_container, from)
          set_date(:daterange_picker_end_container, to)
        end

        # Return lifecycle metric
        # If metric is a simple scalar value, integer is returned, otherwise returns string with the unit of value
        #
        # @param [Symbol] type type of lifecycle metric, example: lead_time, cycle_time, issues, commits, deploys
        # @return [<String, Integer>]
        def lifecycle_metric(type)
          within_element("##{type}") do
            value = find_element("displayValue").text
            unit = has_element?("unit", wait: 0) ? find_element("unit").text : nil

            unit ? "#{value} #{unit}" : value.to_i
          end
        end

        private

        # Select type of value stream
        #
        # @param [String] value
        # @return [void]
        def select_value_stream_type(value = 'default')
          within_element(:vsa_preset_selector) do
            # template selectors use generic GlFormRadioGroup vue component which does not support
            # testid selectors so we need to select based on radio value
            choose_element("input[name='preset'][value='#{value}']", true, visible: :all)
          end
        end

        # Click create value stream button
        #
        # @return [void]
        def create_value_stream
          within_element(:value_stream_form_modal) do
            # footer buttons are generic UI components from gitlab/ui
            find_button("Create value stream").click
          end
        end

        # Add another stage to custom vsa template
        #
        # @return [void]
        def add_another_stage
          within_element(:value_stream_form_modal) do
            find_button("Add another stage").click
          end
        end

        # Select custom event in stage
        #
        # @param [String] event_type start or end
        # @param [Integer] stage_index index number of stage
        # @param [String] event_name name of the custom event from the dropdown
        # @return [void]
        def select_custom_event(event_type, stage_index, event_name)
          within_element(:"custom-stage-#{event_type}-event-#{stage_index}") do
            click_element(:chevron_down_icon)
            click_element("button[value=#{event_name.downcase.tr(' ', '_')}]")
          end
        end

        # Set date from date picker field
        #
        # @param [Symbol] input_element
        # @param [String] date
        # @return [void]
        def set_date(input_element, date)
          within_element(input_element) do
            find_element(:gl_datepicker_input).then do |input|
              input.set(date)
              input.send_keys(:enter)
            end
          end

          finished_loading?
        end
      end
    end
  end
end
