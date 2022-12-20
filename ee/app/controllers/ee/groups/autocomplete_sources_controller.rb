# frozen_string_literal: true

module EE
  module Groups
    module AutocompleteSourcesController
      extend ActiveSupport::Concern

      prepended do
        feature_category :portfolio_management, [:epics]
        feature_category :team_planning, [:iterations]
        urgency :medium, [:epics, :iterations]
        feature_category :vulnerability_management, [:vulnerabilities]
        urgency :low, [:vulnerabilities]
      end

      def epics
        render json: issuable_serializer.represent(
          autocomplete_service.epics(confidential_only: params[:confidential_only]),
          parent_group: group
        )
      end

      def iterations
        return render_404 unless group.licensed_feature_available?(:iterations)

        render json: iteration_serializer.represent(autocomplete_service.iterations)
      end

      def vulnerabilities
        render json: vulnerability_serializer.represent(autocomplete_service.vulnerabilities, parent_group: group)
      end

      private

      def iteration_serializer
        ::Autocomplete::IterationSerializer.new
      end

      def vulnerability_serializer
        GroupVulnerabilityAutocompleteSerializer.new
      end
    end
  end
end
