# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Component
          attr_reader :component_type, :name, :version

          def initialize(component_data = {})
            @component_type = component_data['type']
            @name = component_data['name']
            @version = component_data['version']
          end
        end
      end
    end
  end
end
