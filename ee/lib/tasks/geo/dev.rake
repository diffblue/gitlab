# frozen_string_literal: true

namespace :geo do
  namespace :dev do
    desc 'GitLab | Geo | Dev | Add Ssf metrics to geo_node_status.json'
    task ssf_metrics: :environment do
      base = {
        type: "array",
        items: {
          type: "object",
          properties: {}
        }
      }
      config_path = Rails.root.join("ee/config/metrics/object_schemas/geo_node_usage.json")
      properties = {}
      GeoNodeStatus::RESOURCE_STATUS_FIELDS.each do |field|
        properties[field] = {
          description: field.humanize,
          type: 'number'
        }
      end

      base[:items][:properties] = properties.sort.to_h
      ::File.open(config_path, "w") { |f| f.puts Gitlab::Json.pretty_generate(base) }
    end
  end
end
