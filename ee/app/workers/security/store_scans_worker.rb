# frozen_string_literal: true

module Security
  class StoreScansWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    worker_resource_boundary :cpu
    sidekiq_options retry: 3
    include SecurityScansQueue

    feature_category :vulnerability_management

    def perform(pipeline_id)
      ::Ci::Pipeline.find_by_id(pipeline_id).try do |pipeline|
        break unless pipeline.can_store_security_reports?

        record_onboarding_progress(pipeline)

        Security::StoreScansService.execute(pipeline)
      end
    end

    private

    def record_onboarding_progress(pipeline)
      recordable_scan_actions = Security::Scan.scan_types.keys
        .inject({}) { |hash, scan_type| hash.merge!(scan_type => "secure_#{scan_type}_run".to_sym) }
        .merge('sast' => :security_scan_enabled) # sast has an exceptional action name

      actions = pipeline.security_scans.distinct_scan_types.map { |scan_type| recordable_scan_actions[scan_type] }
      Onboarding::ProgressService.new(pipeline.project.namespace).execute(action: actions)
    end
  end
end
