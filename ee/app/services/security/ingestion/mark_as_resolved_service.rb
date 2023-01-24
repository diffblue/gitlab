# frozen_string_literal: true

module Security
  module Ingestion
    # This service class takes the IDs of recently ingested
    # vulnerabilities for a project which had been previously
    # detected by the same scanner, and marks them as resolved
    # on the default branch if they were not detected again.
    class MarkAsResolvedService
      def self.execute(scanner, ingested_ids)
        new(scanner, ingested_ids).execute
      end

      def initialize(scanner, ingested_ids)
        @scanner = scanner
        @ingested_ids = ingested_ids
      end

      def execute
        return unless scanner

        vulnerability_reads
          .by_scanner(scanner)
          .each_batch { |batch| process_batch(batch) }
      end

      private

      attr_reader :ingested_ids, :scanner

      delegate :project, to: :scanner, private: true
      delegate :vulnerability_reads, to: :project, private: true

      def process_batch(batch)
        (batch.pluck_primary_key - ingested_ids).then { |missing_ids| mark_as_resolved(missing_ids) }
      end

      def mark_as_resolved(missing_ids)
        return if missing_ids.blank?

        Vulnerability.id_in(missing_ids)
                     .with_resolution(false)
                     .not_generic
                     .update_all(resolved_on_default_branch: true)
      end
    end
  end
end
