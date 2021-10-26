# frozen_string_literal: true

module Epics
  class UpdateEpicsDatesWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :epics
    feature_category :portfolio_management

    def perform(epic_ids)
      return if epic_ids.blank?

      Epics::UpdateDatesService.new(Epic.id_in(epic_ids)).execute
    end
  end
end
