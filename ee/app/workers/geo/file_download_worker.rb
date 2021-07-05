# frozen_string_literal: true

module Geo
  class FileDownloadWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue

    sidekiq_options retry: 3, dead: false
    loggable_arguments 0

    def perform(object_type, object_id)
      Geo::FileDownloadService.new(object_type.to_sym, object_id).execute
    end
  end
end
