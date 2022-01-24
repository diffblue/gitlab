# frozen_string_literal: true

module EE
  module Groups
    module AutocompleteSourcesController
      extend ActiveSupport::Concern

      prepended do
        feature_category :portfolio_management, [:epics]
        urgency :medium, [:epics]
        feature_category :vulnerability_management, [:vulnerabilities]
      end

      def epics
        render json: issuable_serializer.represent(
          autocomplete_service.epics(confidential_only: params[:confidential_only]),
          parent_group: group
        )
      end

      def vulnerabilities
        render json: vulnerability_serializer.represent(autocomplete_service.vulnerabilities, parent_group: group)
      end

      private

      def vulnerability_serializer
        GroupVulnerabilityAutocompleteSerializer.new
      end
    end
  end
end
