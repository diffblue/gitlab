# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Pipeline
        module Seed
          module Build
            extend ::Gitlab::Utils::Override

            override :attributes
            def initialize(context, attributes, previous_stages, current_stage = nil)
              super

              @dast_configuration = attributes.dig(:options, :dast_configuration)
            end

            override :attributes
            def attributes
              super.deep_merge(dast_configuration.payload)
            end

            override :errors
            def errors
              strong_memoize(:errors) do
                super.concat(dast_configuration.errors)
              end
            end

            private

            # rubocop:disable Gitlab/ModuleWithInstanceVariables
            def dast_configuration
              return ServiceResponse.success unless @dast_configuration && @seed_attributes[:stage] == 'dast'

              strong_memoize(:dast_attributes) do
                AppSec::Dast::Profiles::BuildConfigService.new(
                  project: @pipeline.project,
                  current_user: @pipeline.user,
                  params: {
                    dast_site_profile: @dast_configuration[:site_profile],
                    dast_scanner_profile: @dast_configuration[:scanner_profile]
                  }
                ).execute
              end
            end
            # rubocop:enable Gitlab/ModuleWithInstanceVariables
          end
        end
      end
    end
  end
end
