# frozen_string_literal: true

module Resolvers
  class DastSiteProfileResolver < BaseResolver
    include LooksAhead

    alias_method :project, :object

    type Types::DastSiteProfileType.connection_type, null: true

    when_single do
      argument :id, ::Types::GlobalIDType[::DastSiteProfile],
               required: true,
               description: "ID of the site profile."
    end

    def resolve_with_lookahead(**args)
      apply_lookahead(find_dast_site_profiles(args))
    end

    private

    def preloads
      {
        request_headers: [:secret_variables],
        auth: [:secret_variables]
      }
    end

    def find_dast_site_profiles(args)
      if args[:id]
        gid = args[:id]
        DastSiteProfilesFinder.new(project_id: project.id, id: gid.model_id).execute
      else
        DastSiteProfilesFinder.new(project_id: project.id).execute
      end
    end
  end
end
