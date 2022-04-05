# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # This module populates the `finding_uuid` attribute for
      # the existing `vulnerability_feedback` records.
      module PopulateUuidsForSecurityFindings
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        class Artifact < ActiveRecord::Base
          include FileStoreMounter

          NotSupportedAdapterError = Class.new(StandardError)

          FILE_FORMAT_ADAPTERS = {
            gzip: ::Gitlab::Ci::Build::Artifacts::Adapters::GzipStream,
            raw: ::Gitlab::Ci::Build::Artifacts::Adapters::RawStream
          }.freeze

          self.table_name = :ci_job_artifacts

          mount_file_store_uploader JobArtifactUploader

          belongs_to :build, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::Build', foreign_key: :job_id

          enum file_type: {
            trace: 3,
            sast: 5,
            dependency_scanning: 6,
            container_scanning: 7,
            dast: 8,
            secret_detection: 21,
            coverage_fuzzing: 23,
            api_fuzzing: 26
          }

          enum file_format: {
            raw: 1,
            zip: 2,
            gzip: 3
          }, _suffix: true

          enum file_location: {
            legacy_path: 1,
            hashed_path: 2
          }

          def security_report
            return if expired? || !build&.pipeline

            report = ::Gitlab::Ci::Reports::Security::Report.new(file_type, build.pipeline, nil).tap do |report|
              each_blob do |blob|
                ::Gitlab::Ci::Parsers.fabricate!(file_type, blob, report).parse!
              end
            end

            ::Security::MergeReportsService.new(report).execute
          end

          # Used by the `JobArtifactUploader`
          def hashed_path?
            return true if trace?

            super || self.file_location.nil?
          end

          private

          def expired?
            expire_at.present? && expire_at < Time.current
          end

          # Copied from Ci::Artifactable
          def each_blob(&blk)
            unless file_format_adapter_class
              raise NotSupportedAdapterError, 'This file format requires a dedicated adapter'
            end

            file.open do |stream|
              file_format_adapter_class.new(stream).each_blob(&blk)
            end
          end

          def file_format_adapter_class
            FILE_FORMAT_ADAPTERS[file_format.to_sym]
          end
        end

        class Project < ActiveRecord::Base
          self.table_name = :projects
        end

        class Pipeline < ActiveRecord::Base
          self.table_name = :ci_pipelines

          belongs_to :project, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::Project', foreign_key: :project_id
        end

        class Build < ActiveRecord::Base
          self.table_name = :ci_builds
          self.inheritance_column = nil

          belongs_to :pipeline, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::Pipeline', foreign_key: :commit_id
          has_many :artifacts, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::Artifact', foreign_key: :job_id
        end

        class SecurityScan < ActiveRecord::Base
          self.table_name = :security_scans

          belongs_to :build, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::Build'
          has_one :pipeline, through: :build
          has_many :artifacts, through: :build
          has_many :findings, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::SecurityFinding', foreign_key: :scan_id

          enum scan_type: {
            sast: 1,
            dependency_scanning: 2,
            container_scanning: 3,
            dast: 4,
            secret_detection: 5,
            coverage_fuzzing: 6,
            api_fuzzing: 7
          }

          def recover_findings
            populate_finding_uuids
            remove_broken_findings
            set_feedback_finding_uuids
          rescue StandardError => error
            ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(error)
          end

          def raw_scan_type
            self.class.scan_types[scan_type]
          end

          private

          def populate_finding_uuids
            report_findings.each_with_index do |report_finding, index|
              findings.where(position: index)
                      .update_all(uuid: report_finding.uuid)
            end
          end

          def remove_broken_findings
            findings.where(uuid: nil).each_batch { |batch| batch.delete_all }
          end

          def set_feedback_finding_uuids
            findings.each(&:feedback) # This will trigger batchloader

            findings.each do |finding|
              report_finding = report_findings[finding.position]

              next unless report_finding && finding.feedback.present? && !finding.feedback.finding_uuid

              finding.feedback.update_column(:finding_uuid, report_finding.uuid)
            end
          end

          def report_findings
            @report_findings ||= security_reports&.findings.to_a
          end

          def security_reports
            related_artifact&.security_report
          end

          def related_artifact
            artifacts.find { |artifact| artifact.file_type == scan_type }
          end
        end

        class Feedback < ActiveRecord::Base
          self.table_name = :vulnerability_feedback

          def finding_key
            {
              project_id: project_id,
              category: category,
              project_fingerprint: project_fingerprint
            }
          end
        end

        class SecurityFinding < ActiveRecord::Base
          include EachBatch

          self.table_name = :security_findings

          belongs_to :scan, class_name: '::Gitlab::BackgroundMigration::PopulateUuidsForSecurityFindings::SecurityScan', foreign_key: :scan_id

          scope :without_uuid, -> { where(uuid: nil) }

          def feedback
            BatchLoader.for(finding_key).batch do |finding_keys, loader|
              project_ids = finding_keys.map { |key| key[:project_id] }
              categories = finding_keys.map { |key| key[:category] }
              fingerprints = finding_keys.map { |key| key[:project_fingerprint] }

              feedback_records = Feedback.where(
                project_id: project_ids.uniq,
                category: categories.uniq,
                project_fingerprint: fingerprints.uniq
              ).to_a

              finding_keys.each do |finding_key|
                loader.call(
                  finding_key,
                  feedback_records.find { |f| finding_key == f.finding_key }
                )
              end
            end
          end

          private

          def finding_key
            {
              project_id: scan.pipeline.project_id,
              category: scan.raw_scan_type - 1, # scan_type on Scan model starts from `1` but the category on Feedback starts from `0`
              project_fingerprint: project_fingerprint
            }
          end
        end

        class_methods do
          def security_findings
            SecurityFinding.without_uuid.distinct
          end
        end

        override :perform
        def perform(*scan_ids)
          SecurityScan.where(id: scan_ids).includes(:pipeline, :artifacts).each(&:recover_findings)

          log_info(scan_ids.count)
        end

        def log_info(scans_count)
          ::Gitlab::BackgroundMigration::Logger.info(
            migrator: self.class.name,
            message: '`uuid` attributes has been set',
            count: scans_count
          )
        end
      end
    end
  end
end
