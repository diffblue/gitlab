# frozen_string_literal: true

module Resolvers
  module AppSec
    module Dast
      class ProfileResolver < BaseResolver
        include LooksAhead

        alias_method :project, :object

        type ::Types::Dast::ProfileType.connection_type, null: true

        when_single do
          argument :id, ::Types::GlobalIDType[::Dast::Profile],
                   required: true,
                   description: 'ID of the DAST Profile.'
        end

        def resolve_with_lookahead(**args)
          apply_lookahead(find_dast_profiles(args))
        end

        private

        def preloads
          {
            dast_site_profile: [{ dast_site_profile: [:dast_site, :secret_variables] }],
            dast_scanner_profile: [:dast_scanner_profile]
          }
        end

        def find_dast_profiles(args)
          params = { project_id: project.id }

          if args[:id]
            # TODO: remove this coercion when the compatibility layer is removed
            # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
            params[:id] = ::Types::GlobalIDType[::Dast::Profile].coerce_isolated_input(args[:id]).model_id
          end

          ::Dast::ProfilesFinder.new(params).execute
        end
      end
    end
  end
end
