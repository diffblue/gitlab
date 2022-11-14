# frozen_string_literal: true

module EE
  module API
    module Entities
      class Experiment < Grape::Entity
        expose :key, documentation: { type: 'string', example: 'code_quality_walkthrough' } do |definition|
          definition.attributes[:name].gsub(/_experiment_percentage$/, '')
        end

        expose :definition, using: ::API::Entities::Feature::Definition do |feature|
          ::Feature::Definition.definitions[feature.name.to_sym]
        end

        class CurrentStatus < Grape::Entity
          expose :state
          expose :gates, using: ::API::Entities::FeatureGate do |model|
            model.gates.map do |gate|
              value = model.gate_values[gate.key]

              # By default all gate values are populated. Only show relevant ones.
              if (value.is_a?(Integer) && value == 0) || (value.is_a?(Set) && value.empty?)
                next
              end

              { key: gate.key, value: value }
            end.compact
          end
        end

        expose :current_status, using: CurrentStatus do |definition|
          feature(definition)
        end

        private

        def feature(definition)
          @feature ||= ::Feature.get(definition.attributes[:name]) # rubocop:disable Gitlab/AvoidFeatureGet
        end
      end
    end
  end
end
