# frozen_string_literal: true

class Gitlab::Seeder::ComplianceReportViolations
  include MergeRequestMetricsHelper

  def initialize(project)
    @project = project
  end

  attr_reader :project

  def seed!
    Array.new(rand(2..10)).each do
      user = project.members.sample&.user
      next unless user

      merge_request = create_merge_request([{ user: user }])

      ::Enums::MergeRequests::ComplianceViolation.reasons.keys.each do |reason|
        FactoryBot.create(
          :compliance_violation,
          reason,
          merge_request: merge_request,
          violating_user: merge_request.metrics.merged_by
        )

        print '.'
      end
    end
  end

  private

  def create_merge_request(approvers)
    merge_request = FactoryBot.create(
      :merge_request,
      state: :merged,
      source_project: project,
      target_project: project,
      source_branch: "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}",
      target_branch: project.default_branch,
      title: FFaker::Lorem.sentence(6),
      description: FFaker::Lorem.sentence,
      author: approvers.first[:user]
    )
    merge_request.approvals.create(approvers)

    metrics = merge_request.build_metrics
    metrics.merged_at = rand(1..30).days.ago
    metrics.merged_by = approvers.first[:user]
    metrics.save!

    merge_request
  end
end

Gitlab::Seeder.quiet do
  projects = Project
      .non_archived
      .with_merge_requests_enabled
      .not_mass_generated
      .reject(&:empty_repo?)

  projects.each do |project|
    violations = Gitlab::Seeder::ComplianceReportViolations.new(project)
    violations.seed!
  end
end
