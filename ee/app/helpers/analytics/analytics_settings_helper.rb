# frozen_string_literal: true

module Analytics
  module AnalyticsSettingsHelper
    def product_analytics_configurator_connection_string_data(form_name:, value:)
      analytics_input_copy_visibility_data(
        "#{form_name}[product_analytics_configurator_connection_string]",
        value,
        'https://username:password@gl-configurator.gitlab.com',
        s_('ProductAnalytics|Connection string'),
        s_('ProductAnalytics|The connection string for your Snowplow configurator instance.')
      )
    end

    def clickhouse_connection_string_data(form_name:, value:)
      analytics_input_copy_visibility_data(
        "#{form_name}[product_analytics_clickhouse_connection_string]",
        value,
        'https://user:pass@clickhouse.gitlab.com:8123',
        s_('ProductAnalytics|Clickhouse URL'),
        s_('ProductAnalytics|Used to connect Snowplow to the Clickhouse instance.')
      )
    end

    def cube_api_key_data(form_name:, value:)
      analytics_input_copy_visibility_data(
        "#{form_name}[cube_api_key]",
        value,
        nil,
        s_('ProductAnalytics|Cube API key'),
        s_('ProductAnalytics|Used to retrieve dashboard data from the Cube instance.')
      )
    end

    private

    def analytics_input_copy_visibility_data(name, value, placeholder, label, description)
      {
        name: name,
        value: value,
        form_input_group_props: {
          placeholder: placeholder,
          id: name
        }.to_json,
        form_group_attributes: {
          label: label,
          label_for: name,
          description: description
        }.to_json
      }
    end
  end
end
