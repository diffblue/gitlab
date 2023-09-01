# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module SyncScanResultPolicies
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        prepended do
          operation_name :sync_scan_result_policies
        end

        override :perform
        def perform
          each_sub_batch do |sub_batch|
            sub_batch.pluck(:id).each do |config_id|
              ::Security::SyncScanPoliciesWorker.perform_async(config_id)
            end
          end
        end
      end
    end
  end
end
