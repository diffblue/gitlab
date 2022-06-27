# frozen_string_literal: true

module IncidentManagement
  class IssuableResourceLinksFinder
    def initialize(user, incident, params = {})
      @user = user
      @incident = incident
      @params = params
    end

    def execute
      return ::IncidentManagement::IssuableResourceLink.none unless allowed?

      collection = incident.issuable_resource_links
      sort(collection)
    end

    private

    attr_reader :user, :incident, :params

    def allowed?
      Ability.allowed?(user, :read_issuable_resource_link, incident)
    end

    def sort(collection)
      collection.order_by_created_at_asc
    end
  end
end
