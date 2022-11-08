# frozen_string_literal: true

module EE
  module API
    module Entities
      module Analytics
        module CodeReview
          class MergeRequest < ::API::Entities::MergeRequestSimple
            expose :milestone, using: ::API::Entities::Milestone
            expose :author, using: ::API::Entities::UserBasic
            expose :approved_by_users, as: :approved_by, using: ::API::Entities::UserBasic
            expose :notes_count, documentation: { type: 'integer', example: 10 } do |mr|
              if options[:issuable_metadata]
                # Avoids an N+1 query when metadata is included
                options[:issuable_metadata][mr.id].user_notes_count
              else
                mr.notes.user.count
              end
            end
            expose :review_time, documentation: { type: 'integer', example: 6, desc: 'Review time in hours' } do |mr|
              time = mr.metrics.review_time

              next unless time

              (time / ActiveSupport::Duration::SECONDS_PER_HOUR).floor
            end
            expose :diff_stats

            private

            # rubocop: disable CodeReuse/ActiveRecord
            def diff_stats
              result = {
                additions: object.diffs.diff_files.sum(&:added_lines),
                deletions: object.diffs.diff_files.sum(&:removed_lines),
                commits_count: object.commits_count
              }
              result[:total] = result[:additions] + result[:deletions]
              result
            end
            # rubocop: enable CodeReuse/ActiveRecord
          end
        end
      end
    end
  end
end
