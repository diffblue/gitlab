# frozen_string_literal: true

# Finder for retrieving organizations scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
#     name: String, optional
module Crm
  class OrganizationsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return CustomerRelations::Organization.none unless root_group

      organizations = root_group.organizations
      organizations = by_name(organizations)
      organizations = by_state(organizations)
      organizations.order_by(:name)
    end

    private

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_organization, group)

        group
      end
    end

    def by_name(organizations)
      return organizations unless name?

      organizations.search(params[:name])
    end

    def by_state(organizations)
      return organizations unless state?

      organizations.where(state: params[:state])
    end

    def name?
      params[:name].present?
    end

    def state?
      params[:state].present?
    end
  end
end
