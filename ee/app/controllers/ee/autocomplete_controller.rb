# frozen_string_literal: true

module EE
  module AutocompleteController
    extend ::ActiveSupport::Concern

    prepended do
      feature_category :subgroups, [:project_groups, :namespace_routes, :group_subgroups]
      feature_category :projects, [:project_routes]
      urgency :high, [:project_groups]
    end

    def project_groups
      groups = ::Autocomplete::ProjectInvitedGroupsFinder
        .new(current_user, params)
        .execute

      render json: ::Autocomplete::GroupSerializer.new.represent(groups)
    end

    def group_subgroups
      groups = ::Autocomplete::GroupSubgroupsFinder
        .new(current_user, params)
        .execute

      render json: ::Autocomplete::GroupSerializer.new.represent(groups)
    end

    def project_routes
      routes = ::Autocomplete::RoutesFinder::ProjectsOnly
                 .new(current_user, params)
                 .execute

      render json: RouteSerializer.new.represent(routes)
    end

    def namespace_routes
      routes = ::Autocomplete::RoutesFinder::NamespacesOnly
                 .new(current_user, params)
                 .execute

      render json: RouteSerializer.new.represent(routes)
    end
  end
end
