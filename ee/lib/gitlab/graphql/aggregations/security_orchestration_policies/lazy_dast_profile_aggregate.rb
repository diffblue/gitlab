# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module SecurityOrchestrationPolicies
        class LazyDastProfileAggregate
          include ::Gitlab::Graphql::Deferred

          attr_reader :dast_profile, :lazy_state

          def initialize(query_ctx, dast_profile)
            raise ArgumentError, 'only DastSiteProfile or DastScannerProfile are allowed' if !dast_profile.is_a?(DastSiteProfile) && !dast_profile.is_a?(DastScannerProfile)

            @dast_profile = Gitlab::Graphql::Lazy.force(dast_profile)
            # Initialize the loading state for this query,
            # or get the previously-initiated state
            @lazy_state = query_ctx[:lazy_dast_profile_in_policies_aggregate] ||= {
              dast_pending_profiles: [],
              loaded_objects: {}
            }
            # Register this ID to be loaded later:
            @lazy_state[:dast_pending_profiles] << dast_profile
          end

          # Return the loaded record, hitting the database if needed
          def execute
            # Check if the record was already loaded
            if @lazy_state[:dast_pending_profiles].present?
              load_records_into_loaded_objects
            end

            @lazy_state[:loaded_objects][@dast_profile]
          end

          private

          def load_records_into_loaded_objects
            # The record hasn't been loaded yet, so
            # hit the database with all pending IDs to prevent N+1
            profiles_by_project_id = @lazy_state[:dast_pending_profiles].group_by(&:project_id)
            policy_configurations = Security::OrchestrationPolicyConfiguration.for_project(profiles_by_project_id.keys).index_by(&:project_id)

            profiles_by_project_id.each do |project_id, dast_pending_profiles|
              dast_pending_profiles.each do |profile|
                @lazy_state[:loaded_objects][profile] = active_policy_names_for_profile(policy_configurations[project_id], profile)
              end
            end

            @lazy_state[:dast_pending_profiles].clear
          end

          def active_policy_names_for_profile(policy_configuration, profile)
            return [] if policy_configuration.blank?

            case profile
            when DastSiteProfile
              policy_configuration.active_policy_names_with_dast_site_profile(profile.name)
            when DastScannerProfile
              policy_configuration.active_policy_names_with_dast_scanner_profile(profile.name)
            end
          end
        end
      end
    end
  end
end
