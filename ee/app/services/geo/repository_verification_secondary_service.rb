# frozen_string_literal: true

module Geo
  class RepositoryVerificationSecondaryService < BaseRepositoryVerificationService
    include ::Gitlab::Utils::StrongMemoize

    def initialize(project_repository_registry, type)
      @project_repository_registry = project_repository_registry
      @type = type.to_sym
    end

    def execute
      return unless Gitlab::Geo.geo_database_configured?
      return unless Gitlab::Geo.secondary?
      return unless should_verify_checksum?

      verification_started!
      verify_checksum
    end

    private

    attr_reader :project_repository_registry, :type

    delegate :project, to: :project_repository_registry
    delegate :repository_state, :wiki_repository_state, to: :project, allow_nil: true

    def should_verify_checksum?
      return false if resync?
      return false unless primary_checksummed?

      mismatch?(secondary_checksum)
    end

    def resync?
      case type
      when :repository then project_repository_registry.resync_repository
      when :wiki then wiki_repository_registry&.failed? || project_repository_registry.resync_wiki
      end
    end

    def primary_checksummed?
      primary_checksum.present?
    end

    def primary_checksum
      case type
      when :repository then primary_project_repository_checksum
      when :wiki then primary_wiki_repository_checksum
      end
    end
    strong_memoize_attr :primary_checksum

    def primary_wiki_repository_checksum
      wiki_repository_state&.verification_checksum || repository_state&.wiki_verification_checksum
    end

    def primary_project_repository_checksum
      repository_state&.repository_verification_checksum
    end

    def secondary_checksum
      case type
      when :repository then secondary_project_repository_checksum
      when :wiki then secondary_wiki_repository_checksum
      end
    end
    strong_memoize_attr :secondary_checksum

    def secondary_wiki_repository_checksum
      wiki_repository_registry.verification_checksum || project_repository_registry.wiki_verification_checksum_sha
    end

    def secondary_project_repository_checksum
      project_repository_registry.repository_verification_checksum_sha
    end

    def mismatch?(checksum)
      primary_checksum != checksum
    end

    def verify_checksum
      checksum = calculate_checksum(repository)
      mismatched = mismatch?(checksum)

      Geo::ProjectRegistry.transaction do
        if mismatched
          update_project_repository_registry!(mismatch: checksum, failure: "#{type.to_s.capitalize} checksum mismatch")
        else
          update_project_repository_registry!(checksum: checksum)
        end

        # Update new table
        next unless wiki_repository_registry_synced?

        if mismatched
          wiki_repository_registry.verification_failed_due_to_mismatch!(checksum, primary_checksum)
        else
          wiki_repository_registry.verification_checksum = checksum
          wiki_repository_registry.verification_succeeded!
        end
      end
    rescue StandardError => e
      Geo::ProjectRegistry.transaction do
        message = "Error calculating #{type} checksum"
        update_project_repository_registry!(failure: message, exception: e)

        # Update new table
        next unless wiki_repository_registry_synced?

        wiki_repository_registry.verification_failed_with_message!(message, e)
      end
    end

    def update_project_repository_registry!(checksum: nil, mismatch: nil, failure: nil, exception: nil)
      reverify, verification_retry_count =
        if mismatch || failure.present?
          log_error(failure, exception, type: type)
          [true, registry_verification_retry_count + 1]
        else
          [false, nil]
        end

      resync_retry_at, resync_retry_count =
        if reverify
          retry_count = registry_retry_count
          calculate_next_retry_attempt(retry_count)
        end

      project_repository_registry.update!(
        "primary_#{type}_checksummed" => primary_checksummed?,
        "#{type}_verification_checksum_sha" => checksum,
        "#{type}_verification_checksum_mismatched" => mismatch,
        "#{type}_checksum_mismatch" => mismatch.present?,
        "last_#{type}_verification_ran_at" => Time.current,
        "last_#{type}_verification_failure" => failure,
        "#{type}_verification_retry_count" => verification_retry_count,
        "resync_#{type}" => reverify,
        "#{type}_retry_at" => resync_retry_at,
        "#{type}_retry_count" => resync_retry_count
      )
    end

    def registry_retry_count
      case type
      when :repository then repository_retry_count
      when :wiki then wiki_retry_count
      end
    end

    def repository_retry_count
      project_repository_registry.repository_retry_count.to_i
    end

    def wiki_retry_count
      [
        wiki_repository_registry&.retry_count,
        project_repository_registry.wiki_retry_count.to_i
      ].max
    end

    def registry_verification_retry_count
      case type
      when :repository then repository_verification_retry_count
      when :wiki then wiki_verification_retry_count
      end
    end

    def repository_verification_retry_count
      project_repository_registry.repository_verification_retry_count.to_i
    end

    def wiki_verification_retry_count
      [
        wiki_repository_registry&.verification_retry_count,
        project_repository_registry.wiki_verification_retry_count.to_i
      ].max
    end

    def verification_started!
      return unless wiki_repository_registry_synced?
      return if wiki_repository_registry.verification_started?

      wiki_repository_registry.verification_started!
    end

    # Keep track of successfully synced registries with a correspondent
    # entry in the `project_wiki_repository_registry` table.
    def wiki_repository_registry_synced?
      type == :wiki && wiki_repository_registry.synced?
    end
    strong_memoize_attr :wiki_repository_registry_synced?

    def wiki_repository_registry
      @wiki_repository_registry ||=
        Geo::ProjectWikiRepositoryRegistry.find_or_initialize_by(project_id: project.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def repository
      @repository ||=
        case type
        when :repository then project.repository
        when :wiki then project.wiki.repository
        end
    end
  end
end
