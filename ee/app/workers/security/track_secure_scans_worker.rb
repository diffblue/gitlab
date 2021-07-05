# frozen_string_literal: true

# Worker for tracking each run of a security scan.
module Security
  class TrackSecureScansWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include SecurityScansQueue

    sidekiq_options retry: 1
    data_consistency :always
    worker_resource_boundary :cpu

    def perform(build_id)
      build = ::Ci::Build.find_by_id(build_id)
      return unless build

      ::Security::TrackScanService.new(build).execute
    end
  end
end
