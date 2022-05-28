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
      contacts = by_name(contacts)
      contacts = by_email(contacts)
      contacts.sort { |a, b| [a.first_name, a.last_name].join(' ') <=> [b.first_name, b.last_name].join(' ') }
    end

    private

    def root_group
      strong_memoize(:root_group) do
        group = params[:group]&.root_ancestor

        next unless can?(@current_user, :read_crm_contact, group)

        group
      end
    end

    def by_name(contacts)
      return contacts if params[:name].nil?
      return contacts.none if params[:name].blank?

      name = params[:name].downcase

      contacts.select do |contact|
        contact_name = [contact.first_name, contact.last_name].join(' ').downcase
        contact_name.include?(name)
      end
    end

    def by_email(contacts)
      return contacts if params[:email].nil?
      return contacts.none if params[:email].blank?

      email = params[:email].downcase

      contacts.select do |contact|
        contact_email = contact.email.downcase
        contact_email.start_with?(email)
      end
    end
  end
end
