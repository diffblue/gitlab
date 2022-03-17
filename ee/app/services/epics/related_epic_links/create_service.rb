# frozen_string_literal: true

module Epics::RelatedEpicLinks
  class CreateService < IssuableLinks::CreateService
    def linkable_issuables(epics)
      @linkable_issuables ||= begin
        epics.select { |epic| can?(current_user, :admin_epic, epic) }
      end
    end

    def previous_related_issuables
      @related_epics ||= issuable.related_epics(current_user).to_a
    end

    private

    def references(extractor)
      extractor.epics
    end

    def extractor_context
      { group: issuable.group }
    end

    def target_issuable_type
      :epic
    end

    def link_class
      Epic::RelatedEpicLink
    end
  end
end
