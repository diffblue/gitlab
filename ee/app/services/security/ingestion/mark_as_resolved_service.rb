# frozen_string_literal: true

module Security
  module Ingestion
    # This service class takes the IDs of recently ingested
    # vulnerabilities for a project and marks the missing
    # vulnerabilities as resolved on default branch.
    class MarkAsResolvedService
      def self.execute(project, ingested_ids)
        new(project, ingested_ids).execute
      end

      def initialize(project, ingested_ids)
        @project = project
        @ingested_ids = ingested_ids
      end

      def execute
        vulnerabilities.each_batch { |batch| process_batch(batch) }
      end

      private

      attr_reader :project, :ingested_ids

      delegate :vulnerabilities, to: :project, private: true

      def process_batch(batch)
        (batch.pluck_primary_key - ingested_ids).then { |missing_ids| mark_as_resolved(missing_ids) }
      end

      def mark_as_resolved(missing_ids)
        return if missing_ids.blank?

        Vulnerability.id_in(missing_ids).update_all(resolved_on_default_branch: true)
      end
    end
  end
end
