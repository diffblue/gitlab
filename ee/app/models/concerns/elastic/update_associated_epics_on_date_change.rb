# frozen_string_literal: true

module Elastic
  module UpdateAssociatedEpicsOnDateChange
    extend ActiveSupport::Concern

    DATE_ATTRIBUTES = %w[due_date due_date_fixed end_date start_date start_date_fixed].freeze

    included do
      after_update_commit :update_associated_epics
    end

    private

    def update_associated_epics
      return unless Gitlab::CurrentSettings.elasticsearch_indexing?
      return unless ::Epic.elasticsearch_available?

      return unless DATE_ATTRIBUTES.any? { |attribute| previous_changes.key?(attribute) }

      epics = case self.class.name
              when 'Epic'
                ::Epic.where('start_date_sourcing_epic_id = :id OR due_date_sourcing_epic_id = :id', id: id)
              when 'Milestone'
                ::Epic.where('start_date_sourcing_milestone_id = :id OR due_date_sourcing_milestone_id = :id', id: id)
              end

      epics.find_in_batches do |batch_of_epics|
        Elastic::ProcessBookkeepingService.track!(*batch_of_epics)
      end
    end
  end
end
