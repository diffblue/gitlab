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
      collection = by_id(collection)
      sort(collection)
    end

    private

    attr_reader :user, :incident, :params

    def allowed?
      Ability.allowed?(user, :admin_issuable_resource_link, incident)
    end

    def by_id(collection)
      return collection unless params[:id]

      collection.id_in(params[:id])
    end

    def sort(collection)
      collection.order_by_created_at_asc
    end
  end
end
