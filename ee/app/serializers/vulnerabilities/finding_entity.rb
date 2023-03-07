# frozen_string_literal: true

class Vulnerabilities::FindingEntity < Grape::Entity
  include RequestAwareEntity
  include VulnerabilitiesHelper
  include MarkupHelper

  expose :id, :report_type, :name, :severity, :confidence
  expose :scanner, using: Vulnerabilities::ScannerEntity
  expose :identifiers, using: Vulnerabilities::IdentifierEntity
  expose :project_fingerprint
  expose :uuid
  expose :create_jira_issue_url do |occurrence|
    create_jira_issue_url_for(occurrence)
  end
  expose :false_positive?, as: :false_positive, if: -> (_, _) { expose_false_positive? }
  expose :create_vulnerability_feedback_issue_path do |occurrence|
    create_vulnerability_feedback_issue_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_merge_request_path do |occurrence|
    create_vulnerability_feedback_merge_request_path(occurrence.project)
  end
  expose :create_vulnerability_feedback_dismissal_path do |occurrence|
    create_vulnerability_feedback_dismissal_path(occurrence.project)
  end

  expose :project, using: ::ProjectEntity

  # :deprecate_vulnerability_feedback
  # These fields should be considered deprecated and their use avoided. However they are provided
  # in case of rollback
  expose :dismissal_feedback, using: Vulnerabilities::FeedbackEntity
  expose :issue_feedback, using: Vulnerabilities::FeedbackEntity
  expose :merge_request_feedback, using: Vulnerabilities::FeedbackEntity
  # /:deprecate_vulnerability_feedback

  expose :state_transitions, using: Vulnerabilities::StateTransitionEntity
  expose :issue_links, using: Vulnerabilities::IssueLinkEntity
  expose :merge_request_links, using: Vulnerabilities::MergeRequestLinkEntity

  expose :metadata, merge: true, if: ->(occurrence, _) { occurrence.raw_metadata } do
    expose :description
    expose :description_html do |model|
      markdown(model.description)
    end
    expose :links
    expose :location
    expose :remediations
    expose :solution
    expose(:evidence) { |model, _| model.evidence&.dig(:summary) }
    expose(:request, using: Vulnerabilities::RequestEntity) { |model, _| model.evidence&.dig(:request) }
    expose(:response, using: Vulnerabilities::ResponseEntity) { |model, _| model.evidence&.dig(:response) }
    expose(:evidence_source) { |model, _| model.evidence&.dig(:source) }
    expose(:supporting_messages) { |model, _| model.evidence&.dig(:supporting_messages) }
    expose(:assets) { |model, _| model.assets }
  end

  expose :details
  expose :state
  expose :scan

  expose :blob_path do |occurrence|
    occurrence.present(presenter_class: Vulnerabilities::FindingPresenter).blob_path
  end

  expose :found_by_pipeline, if: -> (finding, _) { finding.respond_to?(:found_by_pipeline) } do
    expose(:iid) { |finding| finding.found_by_pipeline&.iid }
  end

  alias_method :occurrence, :object

  def current_user
    return request.current_user if request.respond_to?(:current_user)
  end

  private

  def expose_false_positive?
    project = occurrence.project
    project.licensed_feature_available?(:sast_fp_reduction)
  end
end

Vulnerabilities::FindingEntity.include_mod_with('ProjectsHelper')
