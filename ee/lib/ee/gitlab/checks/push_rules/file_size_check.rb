# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class FileSizeCheck < ::Gitlab::Checks::BaseBulkChecker
          LOG_MESSAGE = "Checking if any files are larger than the allowed size..."

          def validate!
            return if push_rule.nil?

            max_file_size = push_rule.max_file_size
            return if max_file_size == 0

            logger.log_timed(LOG_MESSAGE) do
              large_blobs = ::Gitlab::Checks::FileSizeCheck::AnyOversizedBlobs.new(
                project: project,
                changes: changes_access.changes,
                file_size_limit_megabytes: max_file_size
              ).find(timeout: logger.time_left)

              if large_blobs.present?
                raise ::Gitlab::GitAccess::ForbiddenError, %(File "#{large_blobs.first.path}" is larger than the allowed size of #{max_file_size} MiB. Use Git LFS to manage this file.)
              end
            end
          end
        end
      end
    end
  end
end
