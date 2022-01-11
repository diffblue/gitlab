# frozen_string_literal: true

module EE
  module Types
    module Ci
      module PipelineType
        extend ActiveSupport::Concern

        prepended do
          field :security_report_summary,
            ::Types::SecurityReportSummaryType,
            null: true,
            extras: [:lookahead],
            description: 'Vulnerability and scanned resource counts for each security scanner of the pipeline.',
            resolver: ::Resolvers::SecurityReportSummaryResolver

          field :security_report_findings,
            ::Types::PipelineSecurityReportFindingType.connection_type,
            null: true,
            description: 'Vulnerability findings reported on the pipeline.',
            resolver: ::Resolvers::PipelineSecurityReportFindingsResolver

          field :code_quality_reports,
            ::Types::Ci::CodeQualityDegradationType.connection_type,
            null: true,
            description: 'Code Quality degradations reported on the pipeline.'

          field :dast_profile,
            ::Types::Dast::ProfileType,
            null: true,
            description: 'DAST profile associated with the pipeline.'

          def code_quality_reports
            pipeline.codequality_reports.sort_degradations!.values.presence
          end

          def dast_profile
            pipeline.dast_profile
          end
        end
      end
    end
  end
end
