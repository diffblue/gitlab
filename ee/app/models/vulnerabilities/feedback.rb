# frozen_string_literal: true

module Vulnerabilities
  class Feedback < ApplicationRecord
    self.table_name = 'vulnerability_feedback'

    paginates_per 50

    belongs_to :project
    belongs_to :author, class_name: 'User'
    belongs_to :issue
    belongs_to :merge_request
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :pipeline_id
    belongs_to :finding,
               primary_key: :uuid,
               foreign_key: :finding_uuid,
               class_name: 'Vulnerabilities::Finding',
               inverse_of: :feedbacks
    belongs_to :security_finding,
               primary_key: :uuid,
               foreign_key: :finding_uuid,
               class_name: 'Security::Finding',
               inverse_of: :feedbacks

    belongs_to :comment_author, class_name: 'User'

    attr_accessor :vulnerability_data

    enum feedback_type: { dismissal: 0, issue: 1, merge_request: 2 }, _prefix: :for
    enum category: ::Enums::Vulnerability.report_types
    declarative_enum DismissalReasonEnum

    validates :project, presence: true
    validates :author, presence: true
    validates :comment, length: { maximum: 50_000 }
    validates :comment_timestamp, :comment_author, presence: true, if: :comment?
    validates :issue, presence: true, if: :for_issue?
    validates :merge_request, presence: true, if: :for_merge_request?
    validates :vulnerability_data, presence: true, unless: :for_dismissal?
    validates :feedback_type, presence: true
    validates :category, presence: true
    validates :project_fingerprint, presence: true
    validates :pipeline, same_project_association: true, if: :pipeline_id?

    scope :with_associations, -> { includes(:pipeline, :issue, :merge_request, :author, :comment_author) }
    scope :with_merge_request, -> { includes(merge_request: [:author]) }
    scope :by_finding_uuid, -> (uuids) { where(finding_uuid: uuids) }
    scope :by_project, -> (project) { where(project: project) }
    scope :order_by_id_asc, -> { order(id: :asc) }

    scope :preload_author, -> { preload(:author) }
    scope :all_preloaded, -> do
      preload(:author, :comment_author, :project, :issue, :merge_request, :pipeline)
    end

    after_commit :touch_pipeline, if: :for_dismissal?, on: [:create, :update, :destroy]

    # This method should lookup an existing feedback by only the `feedback_type` and `finding_uuid` but historically
    # we were not always setting the `finding_uuid`, therefore, we need to keep using the old lookup mechanism by
    # `category`, `feedback_type`, `project_fingerprint`, and `finding_uuid` as null.
    #
    # The old mechanism should be removed by https://gitlab.com/groups/gitlab-org/-/epics/2791.
    def self.find_or_init_for(feedback_params)
      validate_enums(feedback_params)

      feedback_by_uuid = find_by(feedback_params.slice(:feedback_type, :finding_uuid))
      return feedback_by_uuid.tap { _1.assign_attributes(feedback_params) } if feedback_by_uuid

      feedback_params.slice(:category, :feedback_type, :project_fingerprint)
                     .merge(finding_uuid: nil)
                     .then { find_or_initialize_by(_1) }
                     .tap { _1.assign_attributes(feedback_params) }
    end

    # Rails does not validate enums in select queries such as `find_or_initialize_by`,
    # So we raise an ArgumentError early to return a human-readable error
    def self.validate_enums(feedback_params)
      unless feedback_types.include?(feedback_params[:feedback_type])

        raise ArgumentError, "'#{feedback_params[:feedback_type]}' is not a valid feedback_type"
      end

      unless categories.include?(feedback_params[:category])
        raise ArgumentError, "'#{feedback_params[:category]}' is not a valid category"
      end
    end

    def self.with_category(category)
      where(category: category)
    end

    def self.with_feedback_type(feedback_type)
      where(feedback_type: feedback_type)
    end

    # A hard delete of the comment_author will cause the comment_author to be nil, but the comment
    # will still exist.
    def has_comment?
      comment.present? && comment_author.present?
    end

    def touch_pipeline
      pipeline&.touch if pipeline&.needs_touch?
    rescue ActiveRecord::StaleObjectError
      # Often the pipeline has already been updated by creating vulnerability feedback
      # in batches. In this case, we can ignore the exception as it's already been touched.
    end
  end
end
