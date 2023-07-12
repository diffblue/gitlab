# frozen_string_literal: true

class Geo::ContainerRepositoryRegistry < Geo::BaseRegistry
  include ::Delay
  include ::Geo::ReplicableRegistry
  include ::Geo::VerifiableRegistry
  extend ::Gitlab::Utils::Override

  MODEL_CLASS = ::ContainerRepository
  MODEL_FOREIGN_KEY = :container_repository_id

  belongs_to :container_repository

  ### Remove it after data migration
  # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/371667
  #
  # rubocop:disable Gitlab/NoCodeCoverageComment
  # :nocov: undercoverage spec keeps failing here but this method is covered with tests
  def state
    case value = read_attribute('state')
    when '0', 'pending', nil
      0
    when '1', 'started'
      1
    when '2', 'synced'
      2
    when '3', 'failed'
      3
    else
      value
    end
  end
  # :nocov:
  # rubocop:enable Gitlab/NoCodeCoverageComment
  ### Remove it after data migration

  class << self
    include Delay
    extend ::Gitlab::Utils::Override

    ### Remove it after data migration
    # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/371667
    #
    def without_state(state)
      value = set_state(state)

      where.not(state: value)
    end

    def with_state(state)
      value = set_state(state)

      where(state: value)
    end

    def set_state(state)
      case state.to_sym
      when :pending
        %w[0 pending]
      when :started
        %w[1 started]
      when :synced
        %w[2 synced]
      when :failed
        %w[3 failed]
      end
    end
    ### Remove it after data migration

    def find_registries_needs_sync_again(batch_size:, except_ids: [])
      super.order(arel_table[:last_synced_at].asc.nulls_first)
    end

    def pluck_container_repository_key
      where(nil).pluck(:container_repository_id)
    end

    def replication_enabled?
      Gitlab.config.geo.registry_replication.enabled
    end
  end
end
