# frozen_string_literal: true

# This model represents a single merge request which is on the merge train
module MergeTrains
  class Car < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include AfterCommitQueue

    # For legacy reasons, each row is a merge train in the database
    self.table_name = 'merge_trains'

    ACTIVE_STATUSES = %w[idle stale fresh].freeze
    COMPLETE_STATUSES = %w[merged merging].freeze

    belongs_to :target_project, class_name: "Project"
    belongs_to :merge_request, inverse_of: :merge_train_car
    belongs_to :user
    belongs_to :pipeline, class_name: 'Ci::Pipeline'

    alias_attribute :project, :target_project

    after_destroy do |car|
      run_after_commit do
        ::Ci::CancelPipelineService.new( # rubocop: disable CodeReuse/ServiceClass
          pipeline: car.pipeline,
          current_user: nil).force_execute
        car.cleanup_ref(async: false)
      end
    end

    state_machine :status, initial: :idle do
      event :refresh_pipeline do
        transition %i[idle stale fresh] => :fresh
      end

      event :outdate_pipeline do
        transition fresh: :stale
      end

      event :start_merge do
        transition fresh: :merging
      end

      event :finish_merge do
        transition merging: :merged
      end

      before_transition on: :refresh_pipeline do |car, transition|
        pipeline_id = transition.args.first
        car.pipeline_id = pipeline_id
      end

      before_transition any => :merged do |car|
        merged_at = Time.zone.now
        car.merged_at = merged_at
        car.duration = merged_at - car.created_at
      end

      after_transition fresh: :stale do |car|
        car.run_after_commit do
          car.train.refresh_async
        end
      end

      after_transition merging: :merged do |car|
        car.run_after_commit do
          car.cleanup_ref
        end
      end

      state :idle, value: 0
      state :merged, value: 1
      state :stale, value: 2
      state :fresh, value: 3
      state :merging, value: 4
    end

    scope :active, -> { with_status(*ACTIVE_STATUSES) }
    scope :complete, -> { with_status(*COMPLETE_STATUSES) }
    scope :for_target, ->(project_id, branch) { where(target_project_id: project_id, target_branch: branch) }
    scope :by_id, ->(sort = :asc) { order(id: sort) }

    scope :preload_api_entities, -> do
      preload(:user, :merge_request, pipeline: Ci::Pipeline::PROJECT_ROUTE_AND_NAMESPACE_ROUTE)
        .merge(MergeRequest.preload_routables)
    end

    def all_next
      train.all_cars.where(
        MergeTrains::Car.arel_table[:id].gt(id)
      )
    end

    def all_prev
      train.all_cars.where(
        MergeTrains::Car.arel_table[:id].lt(id)
      )
    end

    def next
      all_next.first
    end

    def prev
      all_prev.last
    end

    def index
      all_prev.count
    end

    def previous_ref
      prev&.merge_request&.train_ref_path || merge_request.target_branch_ref
    end

    def previous_ref_sha
      project.repository.commit(previous_ref)&.sha
    end

    def requires_new_pipeline?
      !has_pipeline? || stale?
    end

    def pipeline_not_succeeded?
      has_pipeline? && pipeline.complete? && !pipeline.success?
    end

    def mergeable?
      has_pipeline? && pipeline&.success? && first_car?
    end

    def first_car?
      train.first_car == self
    end

    def cleanup_ref(async: true)
      if async
        merge_request.schedule_cleanup_refs(only: :train)
      else
        # Synchronous removal might result in Gitaly deadlock
        # Ref.: https://gitlab.com/gitlab-org/gitaly/-/issues/5369
        merge_request.cleanup_refs(only: :train)
      end
    end

    def active?
      ACTIVE_STATUSES.include?(status_name.to_s)
    end

    def train
      Train.new(target_project_id, target_branch)
    end

    private

    def has_pipeline?
      pipeline_id.present? && pipeline
    end
  end
end
