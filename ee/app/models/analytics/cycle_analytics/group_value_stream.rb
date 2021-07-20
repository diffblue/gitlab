# frozen_string_literal: true

class Analytics::CycleAnalytics::GroupValueStream < ApplicationRecord
  belongs_to :group

  has_many :stages, -> { ordered }, class_name: 'Analytics::CycleAnalytics::GroupStage', index_errors: true

  validates :group, :name, presence: true
  validates :name, length: { minimum: 3, maximum: 100, allow_nil: false }, uniqueness: { scope: :group_id }

  accepts_nested_attributes_for :stages, allow_destroy: true

  scope :preload_associated_models, -> { includes(:group, stages: [:group, :end_event_label, :start_event_label]) }

  def custom?
    persisted? || name != Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME
  end

  def self.build_default_value_stream(group)
    new(name: Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME, group: group)
  end
end
