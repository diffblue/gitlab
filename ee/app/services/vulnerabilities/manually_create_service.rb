# frozen_string_literal: true
module Vulnerabilities
  class ManuallyCreateService < CreateServiceBase
    include Gitlab::Allowable

    METADATA_VERSION = "manual:1.0"
    CONFIRMED_MESSAGE = "confirmed_at can only be set when state is confirmed"
    RESOLVED_MESSAGE = "resolved_at can only be set when state is resolved"
    DISMISSED_MESSAGE = "dismissed_at can only be set when state is dismissed"

    def initialize(project, author, params:)
      @project = project
      @author = author
      @params = params
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      timestamps_dont_match_state_message = match_state_fields_with_state
      return ServiceResponse.error(message: timestamps_dont_match_state_message) if timestamps_dont_match_state_message

      vulnerability = initialize_vulnerability(@params[:vulnerability])
      identifiers = initialize_identifiers(@params[:vulnerability][:identifiers])
      scanner = initialize_scanner(@params[:vulnerability][:scanner])
      finding = initialize_finding(
        vulnerability: vulnerability,
        identifiers: identifiers,
        scanner: scanner,
        message: @params[:vulnerability][:message],
        description: @params[:vulnerability][:description],
        solution: @params[:vulnerability][:solution]
      )

      Vulnerability.transaction do
        vulnerability.save!
        finding.save!

        Statistics::UpdateService.update_for(vulnerability)

        ServiceResponse.success(payload: { vulnerability: vulnerability })
      end
    rescue ActiveRecord::RecordNotUnique => e
      Gitlab::AppLogger.error(e.message)
      ServiceResponse.error(message: "Vulnerability with those details already exists")
    rescue ActiveRecord::RecordInvalid => e
      ServiceResponse.error(message: e.message)
    end

    private

    def location_fingerprint(_location_hash)
      uuid = SecureRandom.uuid

      Digest::SHA1.hexdigest("manually-created-vulnerability-#{uuid}")
    end

    def metadata_version
      METADATA_VERSION
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def initialize_scanner(scanner_hash)
      # In database Vulnerabilities::Scanner#id is autoincrementing primary key
      # In the GraphQL mutation mutation arguments we want to respect the security scanner schema:
      # https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/src/security-report-format.json#L339
      # So the id provided to the mutation is actually external_id in our database
      Vulnerabilities::Scanner.find_or_initialize_by(external_id: scanner_hash[:id], project_id: @project.id) do |s|
        s.name = scanner_hash[:name]
        s.vendor = scanner_hash.dig(:vendor, :name).to_s
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

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
  end
end
