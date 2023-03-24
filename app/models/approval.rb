# frozen_string_literal: true

class Approval < ApplicationRecord
  include CreatedAtFilterable
  include Importable

  belongs_to :user
  belongs_to :merge_request

  validates :merge_request_id, presence: true, unless: :importing?
  validates :user_id, presence: true, uniqueness: { scope: [:merge_request_id] }

  scope :with_user, -> { joins(:user) }

  after_create_commit :record_approved_sha
  after_destroy_commit :delete_approved_sha_cache

  def approved_sha
    Gitlab::Redis::SharedState.with do |redis|
      redis.get(approved_sha_cache_key)
    end
  end

  def approved_sha_cache_key
    "Approvals/last_sha_approved/{#{merge_request_id}}approval=#{id}"
  end

  def self.approved_shas_for(eligible_approvals)
    approved_sha_cache_keys = eligible_approvals.map(&:approved_sha_cache_key)

    return [] unless approved_sha_cache_keys.any?

    Gitlab::Redis::SharedState.with do |redis|
      redis.mget(approved_sha_cache_keys).uniq.reject(&:blank?)
    end || []
  end

  private

  def record_approved_sha
    Gitlab::Redis::SharedState.with do |redis|
      redis.set(approved_sha_cache_key, merge_request.diff_head_sha)
    end
  end

  def delete_approved_sha_cache
    Gitlab::Redis::SharedState.with do |redis|
      redis.del(approved_sha_cache_key)
    end
  end
end
