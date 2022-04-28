# frozen_string_literal: true

module Resolvers
  module AppSec
    module Dast
      class ProfileResolver < BaseResolver
        include LooksAhead

        alias_method :project, :object

        type ::Types::Dast::ProfileType.connection_type, null: true

        argument :has_dast_profile_schedule, ::GraphQL::Types::Boolean,
                 required: false,
                 description: 'Filter DAST Profiles by whether or not they have a schedule.'

        when_single do
          argument :id, ::Types::GlobalIDType[::Dast::Profile],
                   required: true,
                   description: 'ID of the DAST Profile.'
        end

        def resolve_with_lookahead(**args)
          profiles = apply_lookahead(find_dast_profiles(args)).to_a
          profiles.each do |profile|
            profile.project = project

            if node_selection&.selects?(:dast_profile_schedule) && profile.dast_profile_schedule
              profile.dast_profile_schedule.project = project
            end
          end
          context[:project_dast_profiles] ||= []
          context[:project_dast_profiles] += profiles

          # If we are querying a single profile, we should return the profile
          # because the late_extensions won't be called
          return profiles if single?

          # We want to avoid resolving any fields on these profiles until all
          # leaves at the name level have been resolved.
          # See: DastProfileConnectionExtension for where this batch is consumed.
          ::Gitlab::Graphql::Lazy.new { profiles }
        end

        private

        def preloads
          {
            dast_site_profile: [{ dast_site_profile: [:dast_site, :secret_variables] }],
            dast_scanner_profile: [:dast_scanner_profile],
            dast_profile_schedule: [{ dast_profile_schedule: [:owner] }]
          }
        end

        def find_dast_profiles(args)
          params = { project_id: project.id, id: args[:id]&.model_id }

          params[:has_dast_profile_schedule] = args[:has_dast_profile_schedule] if args.has_key?(:has_dast_profile_schedule)

          ::Dast::ProfilesFinder.new(params).execute
        end
      end
    end
  end
end
