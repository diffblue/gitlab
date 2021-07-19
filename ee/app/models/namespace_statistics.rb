# frozen_string_literal: true

class NamespaceStatistics < ApplicationRecord
  include AfterCommitQueue

  belongs_to :namespace

  validates :namespace, presence: true

  scope :for_namespaces, -> (namespaces) { where(namespace: namespaces) }
  scope :with_any_ci_minutes_used, -> { where.not(shared_runners_seconds: 0) }

  before_save :update_storage_size
  after_save :update_root_storage_statistics, if: :saved_change_to_storage_size?
  after_destroy :update_root_storage_statistics

  delegate :group?, to: :namespace

  COLUMNS_TO_REFRESH = [:wiki_size].freeze

  def refresh!(only: [])
    return if Gitlab::Database.main.read_only?
    return unless group?

    COLUMNS_TO_REFRESH.each do |column|
      if only.empty? || only.include?(column)
        public_send("update_#{column}") # rubocop:disable GitlabSecurity/PublicSend
      end
    end

    save!
  end

  def update_storage_size
    self.storage_size = wiki_size
  end

  def update_wiki_size
    return unless group_wiki_available?

    self.wiki_size = namespace.wiki.repository.size.megabytes
  end

  private

  def group_wiki_available?
    group? && namespace.feature_available?(:group_wikis)
  end

  def update_root_storage_statistics
    return unless group?

    run_after_commit do
      Namespaces::ScheduleAggregationWorker.perform_async(namespace.id)
    end
  end
end
