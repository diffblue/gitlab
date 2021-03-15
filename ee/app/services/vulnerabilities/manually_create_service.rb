# frozen_string_literal: true
module Vulnerabilities
  class ManuallyCreateService
    include Gitlab::Allowable

    METADATA_VERSION = "manual:1.0"
    GENERIC_REPORT_TYPE = ::Enums::Vulnerability.report_types[:generic]
    MANUAL_LOCATION_FINGERPRINT = Digest::SHA1.hexdigest("manually added").freeze

    CONFIRMED_MESSAGE = "confirmed_at can only be set when state is confirmed"
    RESOLVED_MESSAGE = "resolved_at can only be set when state is resolved"
    DISMISSED_MESSAGE = "dismissed_at can only be set when state is dismissed"

    def initialize(project, author, params:)
      @project = project
      @author = author
      @params = params
    end

    def execute
      unless Feature.enabled?(:create_vulnerabilities_via_api, @project)
        return ServiceResponse.error(message: "create_vulnerabilities_via_api feature flag is not enabled for this project")
      end

      raise Gitlab::Access::AccessDeniedError unless can?(@author, :create_vulnerability, @project)

      timestamps_dont_match_state_message = match_state_fields_with_state
      return ServiceResponse.error(message: timestamps_dont_match_state_message) if timestamps_dont_match_state_message

      vulnerability = initialize_vulnerability(@params[:vulnerability])
      identifiers = initialize_identifiers(@params[:vulnerability][:identifiers])
      scanner = initialize_scanner(@params[:vulnerability][:scanner])
      finding = initialize_finding(vulnerability, identifiers, scanner, @params[:message], @params[:solution])

      Vulnerability.transaction do
        vulnerability.save!
        finding.save!

        Statistics::UpdateService.update_for(vulnerability)
        HistoricalStatistics::UpdateService.update_for(@project)

        ServiceResponse.success(payload: { vulnerability: vulnerability })
      end
    rescue ActiveRecord::RecordNotUnique => e
      Gitlab::AppLogger.error(e.message)
      ServiceResponse.error(message: "Vulnerability with those details already exists")
    rescue ActiveRecord::RecordInvalid => e
      ServiceResponse.error(message: e.message)
    end

    private

    def match_state_fields_with_state
      state = @params.dig(:vulnerability, :state)

      case state
      when "detected"
        return CONFIRMED_MESSAGE if exists_in_vulnerability_params?(:confirmed_at)
        return RESOLVED_MESSAGE if exists_in_vulnerability_params?(:resolved_at)
        return DISMISSED_MESSAGE if exists_in_vulnerability_params?(:dismissed_at)
      when "confirmed"
        return RESOLVED_MESSAGE if exists_in_vulnerability_params?(:resolved_at)
        return DISMISSED_MESSAGE if exists_in_vulnerability_params?(:dismissed_at)
      when "resolved"
        return CONFIRMED_MESSAGE if exists_in_vulnerability_params?(:confirmed_at)
        return DISMISSED_MESSAGE if exists_in_vulnerability_params?(:dismissed_at)
      end
    end

    def exists_in_vulnerability_params?(column_name)
      @params.dig(:vulnerability, column_name.to_sym).present?
    end

    def initialize_vulnerability(vulnerability_hash)
      attributes = vulnerability_hash
        .slice(*%i[
          state
          severity
          confidence
          detected_at
          confirmed_at
          resolved_at
          dismissed_at
        ])
        .merge(
          project: @project,
          author: @author,
          title: vulnerability_hash[:title]&.truncate(::Issuable::TITLE_LENGTH_MAX),
          report_type: GENERIC_REPORT_TYPE
        )

      vulnerability = Vulnerability.new(**attributes)

      vulnerability.confirmed_by = @author if vulnerability.confirmed?
      vulnerability.resolved_by = @author if vulnerability.resolved?
      vulnerability.dismissed_by = @author if vulnerability.dismissed?

      vulnerability
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def initialize_identifiers(identifier_hashes)
      identifier_hashes.map do |identifier|
        name = identifier.dig(:name)
        external_type = map_external_type_from_name(name)
        external_id = name
        fingerprint = Digest::SHA1.hexdigest("#{external_type}:#{external_id}")
        url = identifier.dig(:url)

        Vulnerabilities::Identifier.find_or_initialize_by(name: name) do |i|
          i.fingerprint = fingerprint
          i.project = @project
          i.external_type = external_type
          i.external_id = external_id
          i.url = url
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def map_external_type_from_name(name)
      return 'cve' if name.match?(/CVE/i)
      return 'cwe' if name.match?(/CWE/i)

      'other'
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def initialize_scanner(scanner_hash)
      name = scanner_hash.dig(:name)

      Vulnerabilities::Scanner.find_or_initialize_by(name: name) do |s|
        s.project = @project
        s.external_id = Gitlab::Utils.slugify(name)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def initialize_finding(vulnerability, identifiers, scanner, message, solution)
      uuid = ::Security::VulnerabilityUUID.generate(
        report_type: GENERIC_REPORT_TYPE,
        primary_identifier_fingerprint: identifiers.first.fingerprint,
        location_fingerprint: MANUAL_LOCATION_FINGERPRINT,
        project_id: @project.id
      )

      Vulnerabilities::Finding.new(
        project: @project,
        identifiers: identifiers,
        primary_identifier: identifiers.first,
        vulnerability: vulnerability,
        name: vulnerability.title,
        severity: vulnerability.severity,
        confidence: vulnerability.confidence,
        report_type: vulnerability.report_type,
        project_fingerprint: Digest::SHA1.hexdigest(identifiers.first.name),
        location_fingerprint: MANUAL_LOCATION_FINGERPRINT,
        metadata_version: METADATA_VERSION,
        raw_metadata: {},
        scanner: scanner,
        uuid: uuid,
        message: message,
        solution: solution
      )
    end
  end
end
