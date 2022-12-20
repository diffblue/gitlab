# frozen_string_literal: true

module EE
  module Projects
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
        return render_404 unless project.group.licensed_feature_available?(:epics)

        render json: issuable_serializer.represent(
          autocomplete_service.epics,
          parent_group: project.group&.id
        )
      end

      def iterations
        return render_404 unless project.group.licensed_feature_available?(:iterations)

        render json: iteration_serializer.represent(autocomplete_service.iterations)
      end

      def vulnerabilities
        return render_404 unless project.feature_available?(:security_dashboard)

        render json: autocomplete_service.vulnerabilities
      end

      private

      def iteration_serializer
        ::Autocomplete::IterationSerializer.new
      end

      def issuable_serializer
        GroupIssuableAutocompleteSerializer.new
      end
    end
  end
end
