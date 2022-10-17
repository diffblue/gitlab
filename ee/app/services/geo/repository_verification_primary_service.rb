# frozen_string_literal: true

module Geo
  class RepositoryVerificationPrimaryService < BaseRepositoryVerificationService
    def initialize(project)
      @project = project
    end

    def execute
      verify_checksum(:repository, project.repository)
      verify_checksum(:wiki, project.wiki.repository)

      Geo::ResetChecksumEventStore.new(project).create!
    end

    private

    attr_reader :project

    def verify_checksum(type, repository)
      checksum = calculate_checksum(repository)
      update_repository_state!(type, checksum: checksum)
    rescue StandardError => e
      log_error("Error calculating the #{type} checksum", e, type: type)
      update_repository_state!(type, failure: e.message)
    end

    def update_repository_state!(type, checksum: nil, failure: nil)
      project.class.transaction do
        update_project_repository_state!(type, checksum: checksum, failure: failure)
        update_wiki_repository_state!(checksum: checksum, failure: failure) if type == :wiki
      end
    end

    def update_project_repository_state!(type, checksum: nil, failure: nil)
      retry_at, retry_count =
        if failure.present?
          calculate_next_retry_attempt(project_repository_state.public_send("#{type}_retry_count")) # rubocop:disable GitlabSecurity/PublicSend
        end

      project_repository_state.update!(
        "#{type}_verification_checksum" => checksum,
        "last_#{type}_verification_ran_at" => Time.current,
        "last_#{type}_verification_failure" => failure,
        "#{type}_retry_at" => retry_at,
        "#{type}_retry_count" => retry_count
      )
    end

    def update_wiki_repository_state!(checksum: nil, failure: nil)
      verified_at = Time.current

      retry_at, retry_count =
        if failure.present?
          calculate_next_retry_attempt(wiki_repository_state.verification_retry_count)
        end

      wiki_repository_state.update!(
        verification_checksum: checksum,
        verification_started_at: verified_at,
        verification_failure: failure,
        verification_retry_at: retry_at,
        verification_retry_count: retry_count,
        verified_at: verified_at
      )
    end

    def project_repository_state
      @project_repository_state ||= project.repository_state || project.build_repository_state
    end

    def wiki_repository_state
      @wiki_repository_state ||= project.wiki_repository_state || project.build_wiki_repository_state
    end
  end
end
