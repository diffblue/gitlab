# frozen_string_literal: true

module Security
  # Service for storing a given security report into the database.
  #
  class StoreReportService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :pipeline, :report, :project, :vulnerability_finding_to_finding_map, :new_vulnerabilities

    BATCH_SIZE = 1000

    def initialize(pipeline, report)
      @pipeline = pipeline
      @report = report
      @project = @pipeline.project
      @vulnerability_finding_to_finding_map = {}
      @new_vulnerabilities = []
    end

    def execute
      # Ensure we're not trying to insert data twice for this report
      return error("#{@report.type} report already stored for this pipeline, skipping...") if executed?

      OverrideUuidsService.execute(@report) if override_uuids?

      vulnerability_ids = create_all_vulnerabilities!
      mark_as_resolved_except(vulnerability_ids)
      execute_new_vulnerabilities_hooks

      start_auto_fix

      success
    end

    private

    def executed?
      pipeline.vulnerability_findings.report_type(@report.type).any?
    end

    def override_uuids?
      project.licensed_feature_available?(:vulnerability_finding_signatures)
    end

    def create_all_vulnerabilities!
      # Look for existing Findings using UUID
      finding_uuids = @report.findings.map(&:uuid)
      vulnerability_findings_by_uuid = project.vulnerability_findings
        .where(uuid: finding_uuids) # rubocop: disable CodeReuse/ActiveRecord
        .to_h { |vf| [vf.uuid, vf] }

      update_vulnerability_scanners!(@report.findings)

      vulnerability_ids = @report.findings.map do |finding|
        create_vulnerability_finding(vulnerability_findings_by_uuid, finding)&.id
      end.compact.uniq

      update_vulnerability_links_info if Feature.enabled?(:vulnerability_finding_replace_metadata)
      create_vulnerability_pipeline_objects
      update_vulnerabilities_identifiers
      update_vulnerabilities_finding_identifiers

      if project.licensed_feature_available?(:sast_fp_reduction)
        create_vulnerability_flags_info
      end

      vulnerability_ids
    end

    def execute_new_vulnerabilities_hooks
      new_vulnerabilities.each { |v| v.execute_hooks }
    end

    def mark_as_resolved_except(vulnerability_ids)
      return if ::Vulnerabilities::Finding::REPORT_TYPES_REQUIRING_MANUAL_RESOLUTION.include?(report.type)

      project.vulnerabilities
             .with_report_types(report.type)
             .id_not_in(vulnerability_ids)
             .update_all(resolved_on_default_branch: true)
    end

    def create_vulnerability_finding(vulnerability_findings_by_uuid, finding)
      unless finding.valid?
        put_warning_for(finding)
        return
      end

      vulnerability_params = finding.to_hash.except(:compare_key, :identifiers, :location, :scanner, :scan, :links, :signatures, :flags)
      entity_params = Gitlab::Json.parse(vulnerability_params&.dig(:raw_metadata)).slice('description', 'message', 'solution', 'cve', 'location').symbolize_keys

      # Vulnerabilities::Finding (`vulnerability_occurrences`)
      vulnerability_finding = vulnerability_findings_by_uuid[finding.uuid] ||
        find_or_create_vulnerability_finding(finding, vulnerability_params.merge(entity_params))

      return unless vulnerability_finding

      vulnerability_finding_to_finding_map[vulnerability_finding] = finding

      update_vulnerability_finding(vulnerability_finding, vulnerability_params.merge(location: entity_params[:location], location_fingerprint: finding.location.fingerprint))
      reset_remediations_for(vulnerability_finding, finding)

      if project.licensed_feature_available?(:vulnerability_finding_signatures)
        update_finding_signatures(finding, vulnerability_finding)
      end

      create_vulnerability(vulnerability_finding, pipeline)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_or_create_vulnerability_finding(finding, create_params)
      find_params = {
        scanner: scanners_objects[finding.scanner.key],
        primary_identifier: identifiers_objects[finding.primary_identifier.key],
        location_fingerprint: finding.location.fingerprint
      }

      begin
        # If there's no Finding then we're dealing with one of two cases:
        # 1. The Finding is a new one
        # 2. The Finding is already saved but has UUIDv4
        project.vulnerability_findings
          .create_with(create_params)
          .find_or_initialize_by(find_params).tap do |f|
            f.location = create_params[:location]
            f.uuid = finding.uuid
            f.save!
          end
      rescue ActiveRecord::RecordNotUnique => e
        # This might happen if we're processing another report in parallel and it finds the same Finding
        # faster. In that case we need to perform the lookup again

        vulnerability_finding = project.vulnerability_findings.reset.find_by(uuid: finding.uuid)
        return vulnerability_finding if vulnerability_finding

        vulnerability_finding = project.vulnerability_findings.reset.find_by(find_params)
        return vulnerability_finding if vulnerability_finding

        Gitlab::ErrorTracking.track_and_raise_exception(e, find_params: find_params, uuid: finding.uuid)
      rescue ActiveRecord::RecordInvalid => e
        Gitlab::ErrorTracking.track_exception(e, create_params: create_params&.dig(:raw_metadata))

        nil
      rescue ActiveRecord::ActiveRecordError => e
        Gitlab::ErrorTracking.track_and_raise_exception(e, create_params: create_params&.dig(:raw_metadata))
      end
    end

    def update_vulnerability_scanner(finding)
      scanner = scanners_objects[finding.scanner.key]
      scanner.update!(finding.scanner.to_hash)
    end

    def vulnerability_scanner_attributes_keys
      strong_memoize(:vulnerability_scanner_attributes_keys) do
        Vulnerabilities::Scanner.new.attributes.keys
      end
    end

    def valid_vulnerability_scanner_record?(record)
      return false if (record.keys - vulnerability_scanner_attributes_keys).present?

      record.values.all? {|value| value.present?}
    end

    def create_vulnerability_scanner_records(findings)
      findings.map do |finding|
        scanner = scanners_objects[finding.scanner.key]

        next nil if scanner.nil?

        scanner_attr = scanner.attributes.with_indifferent_access.except(:id)
          .merge(finding.scanner.to_hash)

        scanner_attr.compact!

        scanner_attr
      end
    end

    def update_vulnerability_scanners!(report_findings)
      report_findings.in_groups_of(BATCH_SIZE, false) do |findings|
        records = create_vulnerability_scanner_records(findings)
        records.compact!
        records.uniq!
        records.each { |record| record.merge!({ created_at: Time.current, updated_at: Time.current }) }
        records.filter! { |record| valid_vulnerability_scanner_record?(record) }

        Vulnerabilities::Scanner.insert_all(records) if records.present?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    ensure
      clear_memoization(:scanners_objects)
      clear_memoization(:existing_scanner_objects)
    end

    def update_vulnerability_finding(vulnerability_finding, update_params)
      vulnerability_finding.update!(update_params)
    end

    def update_vulnerabilities_identifiers
      vulnerability_finding_to_finding_map.keys.in_groups_of(BATCH_SIZE, false) do |vulnerability_findings|
        identifier_object_records = get_vulnerability_identifier_objects_for(vulnerability_findings)
        records_with_id, records_without_id = identifier_object_records
                                                .partition { |identifier| identifier[:id].present? }

        update_existing_vulnerability_identifiers_for(records_with_id)
        insert_new_vulnerability_identifiers_for(records_without_id)
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    ensure
      clear_memoization(:identifiers_objects)
      clear_memoization(:existing_identifiers_objects)
    end

    def get_vulnerability_identifier_objects_for(vulnerability_findings)
      timestamps = { created_at: Time.current, updated_at: Time.current }

      vulnerability_findings.flat_map do |vulnerability_finding|
        finding = vulnerability_finding_to_finding_map[vulnerability_finding]
        finding.identifiers.take(Vulnerabilities::Finding::MAX_NUMBER_OF_IDENTIFIERS).map do |identifier|
          identifier_object = identifiers_objects[identifier.key]
          identifier_object.attributes.with_indifferent_access.merge(**timestamps)
                                                        .merge(identifier.to_hash).compact
        end
      end
    end

    def insert_new_vulnerability_identifiers_for(identifier_object_records)
      identifier_object_records = identifier_object_records.uniq.group_by(&:keys).values

      identifier_object_records.each { |records| Vulnerabilities::Identifier.insert_all(records) }
    end

    def update_existing_vulnerability_identifiers_for(identifier_object_records)
      identifier_object_records = identifier_object_records.uniq.group_by(&:keys).values

      identifier_object_records.each { |records| Vulnerabilities::Identifier.upsert_all(records) }
    end

    def update_vulnerabilities_finding_identifiers
      vulnerability_finding_to_finding_map.keys.in_groups_of(BATCH_SIZE, false) do |vulnerability_findings|
        finding_identifier_records = get_finding_identifier_objects_for(vulnerability_findings)
        finding_identifier_records.uniq!
        Vulnerabilities::FindingIdentifier.insert_all(finding_identifier_records) if finding_identifier_records.present?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    def get_finding_identifier_objects_for(vulnerability_findings)
      timestamps = { created_at: Time.current, updated_at: Time.current }

      vulnerability_findings.flat_map do |vulnerability_finding|
        finding = vulnerability_finding_to_finding_map[vulnerability_finding]
        finding.identifiers.take(Vulnerabilities::Finding::MAX_NUMBER_OF_IDENTIFIERS).map do |identifier|
          identifier_object = identifiers_objects[identifier.key]

          next nil unless identifier_object.id

          { occurrence_id: vulnerability_finding.id, identifier_id: identifier_object.id, **timestamps }.compact
        end.compact
      end
    end

    def create_or_update_vulnerability_identifier_object(vulnerability_finding, identifier)
      identifier_object = identifiers_objects[identifier.key]
      vulnerability_finding.finding_identifiers.find_or_create_by!(identifier: identifier_object)
      identifier_object.update!(identifier.to_hash)
    rescue ActiveRecord::RecordNotUnique
    end

    def create_vulnerability_flags_info
      timestamps = { created_at: Time.current, updated_at: Time.current }

      vulnerability_finding_to_finding_map.each_slice(BATCH_SIZE) do |vf_to_findings|
        records = vf_to_findings.flat_map do |vulnerability_finding, finding|
          finding.flags.map { |flag| timestamps.merge(**flag.to_h, vulnerability_occurrence_id: vulnerability_finding.id) }
        end

        records.uniq!

        Vulnerabilities::Flag.insert_all(records) if records.present?

        track_events(records) if records.present?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, project_id: project.id, pipeline_id: pipeline.id)
    end

    def track_events(records)
      records.each do |record|
        Gitlab::Tracking.event(
          self.class.to_s, 'flag_vulnerability', label: record[:flag_type].to_s
        )
      end
    end

    def update_vulnerability_links_info
      timestamps = { created_at: Time.current, updated_at: Time.current }

      vulnerability_finding_to_finding_map.each_slice(BATCH_SIZE) do |vf_to_findings|
        records = vf_to_findings.flat_map do |vulnerability_finding, finding|
          finding.links.map { |link| { vulnerability_occurrence_id: vulnerability_finding.id, **link.to_hash, **timestamps } }
        end

        records.uniq!

        Vulnerabilities::FindingLink.insert_all(records) if records.present?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    def create_or_update_vulnerability_links(finding, vulnerability_finding)
      return if finding.links.blank?

      finding.links.each do |link|
        vulnerability_finding.finding_links.safe_find_or_create_by!(link.to_hash)
      end
    rescue ActiveRecord::RecordNotUnique
    end

    def reset_remediations_for(vulnerability_finding, finding)
      existing_remediations = find_existing_remediations_for(finding)
      new_remediations = build_new_remediations_for(finding, existing_remediations)

      vulnerability_finding.remediations = existing_remediations + new_remediations
    end

    def find_existing_remediations_for(finding)
      checksums = finding.remediations.map(&:checksum)

      @project.vulnerability_remediations.by_checksum(checksums)
    end

    def build_new_remediations_for(finding, existing_remediations)
      find_missing_remediations_for(finding, existing_remediations)
        .map { |remediation| build_vulnerability_remediation(remediation) }
    end

    def find_missing_remediations_for(finding, existing_remediations)
      existing_remediation_checksums = existing_remediations.map(&:checksum)

      finding.remediations.select { |remediation| !remediation.checksum.in?(existing_remediation_checksums) }
    end

    def build_vulnerability_remediation(remediation)
      @project.vulnerability_remediations.new(summary: remediation.summary, file: remediation.diff_file, checksum: remediation.checksum)
    end

    def create_vulnerability_pipeline_objects
      timestamps = { created_at: Time.current, updated_at: Time.current }

      vulnerability_finding_to_finding_map.keys.in_groups_of(BATCH_SIZE, false) do |vulnerability_findings|
        records = vulnerability_findings.map do |vulnerability_finding|
          { occurrence_id: vulnerability_finding.id, pipeline_id: pipeline.id, **timestamps }
        end

        records.uniq!

        Vulnerabilities::FindingPipeline.insert_all(records) if records.present?
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)
    end

    def create_vulnerability_pipeline_object(vulnerability_finding, pipeline)
      vulnerability_finding.finding_pipelines.find_or_create_by!(pipeline: pipeline)
    rescue ActiveRecord::RecordNotUnique
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def update_finding_signatures(finding, vulnerability_finding)
      to_update = {}
      to_create = []

      poro_signatures = finding.signatures.index_by(&:algorithm_type)

      vulnerability_finding.signatures.each do |signature|
        # NOTE: index_by takes the last entry if there are duplicates of the same algorithm, which should never occur.
        poro_signature = poro_signatures[signature.algorithm_type]

        # We're no longer generating these types of signatures. Since
        # we're updating the persisted vulnerability, no need to do anything
        # with these signatures now. We will track growth with
        # https://gitlab.com/gitlab-org/gitlab/-/issues/322186
        next if poro_signature.nil?

        poro_signatures.delete(signature.algorithm_type)
        to_update[signature.id] = poro_signature.to_hash
      end

      # any remaining poro signatures left are new
      poro_signatures.values.each do |poro_signature|
        attributes = poro_signature.to_hash.merge(finding_id: vulnerability_finding.id)
        to_create << ::Vulnerabilities::FindingSignature.new(attributes: attributes, created_at: Time.zone.now, updated_at: Time.zone.now)
      end

      ::Vulnerabilities::FindingSignature.transaction do
        if to_update.count > 0
          ::Vulnerabilities::FindingSignature.update(to_update.keys, to_update.values)
        end

        if to_create.count > 0
          ::Vulnerabilities::FindingSignature.bulk_insert!(to_create)
        end
      end
    end

    def create_vulnerability(vulnerability_finding, pipeline)
      vulnerability = if vulnerability_finding.vulnerability_id
                        Vulnerabilities::UpdateService.new(vulnerability_finding.project, pipeline.user, finding: vulnerability_finding, resolved_on_default_branch: false).execute
                      else
                        Vulnerabilities::CreateService.new(vulnerability_finding.project, pipeline.user, finding_id: vulnerability_finding.id).execute.tap do |vuln|
                          new_vulnerabilities << vuln
                        end
                      end

      create_vulnerability_issue_link(vulnerability)
      vulnerability
    end

    def create_vulnerability_issue_link(vulnerability)
      vulnerability_issue_feedback = vulnerability.finding.feedback(feedback_type: 'issue')
      return unless vulnerability_issue_feedback

      vulnerability.issue_links.safe_find_or_create_by!(issue_id: vulnerability_issue_feedback.issue_id)
    end

    def scanners_objects
      strong_memoize(:scanners_objects) do
        @report.scanners.to_h do |key, scanner|
          [key, existing_scanner_objects[key] || project.vulnerability_scanners.build(scanner&.to_hash)]
        end
      end
    end

    def all_scanners_external_ids
      @report.scanners.values.map(&:external_id)
    end

    def existing_scanner_objects
      strong_memoize(:existing_scanner_objects) do
        project.vulnerability_scanners.with_external_id(all_scanners_external_ids).to_h do |scanner|
          [scanner.external_id, scanner]
        end
      end
    end

    def identifiers_objects
      strong_memoize(:identifiers_objects) do
        @report.identifiers.to_h do |key, identifier|
          [key, existing_identifiers_objects[key] || project.vulnerability_identifiers.build(identifier.to_hash)]
        end
      end
    end

    def all_identifiers_fingerprints
      @report.identifiers.values.map(&:fingerprint)
    end

    def existing_identifiers_objects
      strong_memoize(:existing_identifiers_objects) do
        project.vulnerability_identifiers.with_fingerprint(all_identifiers_fingerprints).to_h do |identifier|
          [identifier.fingerprint, identifier]
        end
      end
    end

    def put_warning_for(finding)
      Gitlab::AppLogger.warn(message: "Invalid vulnerability finding record found", finding: finding.to_hash)
    end

    def start_auto_fix
      return unless auto_fix_enabled?

      ::Security::AutoFixWorker.perform_async(pipeline.id)
    end

    def auto_fix_enabled?
      return false unless project.security_setting&.auto_fix_enabled?

      project.security_setting.auto_fix_enabled_types.include?(report.type.to_sym)
    end
  end
end
