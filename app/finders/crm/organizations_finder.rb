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
      organizations.sort_by(&:name)
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
      return organizations if params[:name].nil?
      return organizations.none if params[:name].blank?

      name = params[:name].downcase

      organizations.select do |org|
        org_name = org.name.downcase
        org_name.start_with?(name)
      end
    end
  end
end
