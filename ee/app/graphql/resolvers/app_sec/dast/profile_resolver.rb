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
          apply_lookahead(find_dast_profiles(args))
        end

        DAST_PROFILE_PRELOAD = {
          dast_site_profile: [{ dast_site_profile: [:dast_site, :secret_variables] }],
          dast_scanner_profile: [:dast_scanner_profile],
          dast_profile_schedule: [:dast_profile_schedule]
        }.freeze

        private

        def preloads
          DAST_PROFILE_PRELOAD
        end

        def find_dast_profiles(args)
          params = { project_id: project.id }

          if args[:id]
            # TODO: remove this coercion when the compatibility layer is removed
            # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
            params[:id] = ::Types::GlobalIDType[::Dast::Profile].coerce_isolated_input(args[:id]).model_id
          end

          params[:has_dast_profile_schedule] = args[:has_dast_profile_schedule] if args.has_key?(:has_dast_profile_schedule)

          ::Dast::ProfilesFinder.new(params).execute
        end
      end
    end
  end
end
