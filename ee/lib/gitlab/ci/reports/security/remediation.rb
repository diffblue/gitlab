# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Remediation
          attr_reader :summary, :diff

          def initialize(summary, diff, start_byte: nil, end_byte: nil)
            @summary = summary
            @diff = diff
            @start_byte = start_byte
            @end_byte = end_byte
          end

          def byte_offsets
            return unless @start_byte && @end_byte

            { start_byte: @start_byte, end_byte: @end_byte }
          end

          def diff_file
            @diff_file ||= DiffFile.new(diff)
          end

          delegate :checksum, to: :diff_file

          class DiffFile < StringIO
            # This method is used by the `carrierwave` gem
            def original_filename
              "#{checksum}.diff"
            end

            def checksum
              @checksum ||= Digest::SHA256.hexdigest(string)
            end
          end
        end
      end
    end
  end
end
