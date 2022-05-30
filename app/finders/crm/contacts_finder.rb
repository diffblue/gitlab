# frozen_string_literal: true

# Finder for retrieving contacts scoped to a group
#
# Arguments:
#   current_user - user performing the action. Must have the correct permission level for the group.
#   params:
#     group: Group, required
#     name: String, optional
module Crm
  class ContactsFinder
    include Gitlab::Allowable
    include Gitlab::Utils::StrongMemoize

    attr_reader :params, :current_user

    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params
    end

    def execute
      return CustomerRelations::Contact.none unless root_group

      contacts = root_group.contacts
      contacts = by_search(contacts)
      contacts.reorder(:first_name)
    end

    private

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_contact, group)

        group
      end
    end

    def by_search(contacts)
      return contacts unless search?

      contacts.search(params[:search])
    end

    def search?
      params[:search].present?
    end
  end
end
