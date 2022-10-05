# frozen_string_literal: true

module EE
  module Gitlab
    module Checks
      module PushRules
        class FileSizeCheck < ::Gitlab::Checks::BaseBulkChecker
          LOG_MESSAGE = "Checking if any files are larger than the allowed size..."

          def validate!
            return if push_rule.nil? || push_rule.max_file_size == 0

            logger.log_timed(LOG_MESSAGE) do
              max_file_size = push_rule.max_file_size

              newrevs = changes_access.changes.map { |change| change[:newrev] }

              blobs = project.repository.new_blobs(newrevs, dynamic_timeout: logger.time_left)

              large_blob = blobs.find do |blob|
                ::Gitlab::Utils.bytes_to_megabytes(blob.size) > max_file_size
              end

              if large_blob
                raise ::Gitlab::GitAccess::ForbiddenError, %Q{File "#{large_blob.path}" is larger than the allowed size of #{max_file_size} MB. Use Git LFS to manage this file.}
              end
            end
          end
        end
      end
    end
  end
end
