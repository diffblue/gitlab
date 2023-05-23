# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ModelConfigurations
        class Base
          MissingConfigurationError = Class.new(StandardError)

          def url
            raise MissingConfigurationError if host.blank? || vertex_project.blank?

            text_model_url = URI::HTTPS.build(
              host: host,
              path: "/v1/projects/#{vertex_project}/locations/us-central1/publishers/google/models/#{model}:predict"
            )
            text_model_url.to_s
          end

          private

          delegate :tofa_host, :vertex_project, to: :settings
          alias_method :host, :tofa_host

          def settings
            @settings ||= Gitlab::CurrentSettings.current_application_settings
          end

          def model
            self.class::NAME
          end
        end
      end
    end
  end
end
