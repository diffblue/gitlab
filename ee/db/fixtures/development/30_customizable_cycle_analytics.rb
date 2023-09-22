# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require 'active_support/testing/time_helpers'
require './spec/support/helpers/cycle_analytics_helpers'
require './ee/db/seeds/shared/dora_metrics' if Gitlab.ee?

# Usage:
#
# Simple invocation always creates a new project:
#
# FILTER=customizable_cycle_analytics SEED_CUSTOMIZABLE_CYCLE_ANALYTICS=1 bundle exec rake db:seed_fu
#
# Run for an existing project
#
# FILTER=customizable_cycle_analytics SEED_CUSTOMIZABLE_CYCLE_ANALYTICS=1 'VSA_SEED_PROJECT_ID'= 13 bundle exec rake db:seed_fu

class Gitlab::Seeder::CustomizableCycleAnalytics
  include ActiveSupport::Testing::TimeHelpers
  include CycleAnalyticsHelpers

  attr_reader :project, :group, :user

  DAYS_BACK = 20
  ISSUE_COUNT = 25
  MERGE_REQUEST_COUNT = 10
  GROUP_LABEL_COUNT = 10

  def initialize(project)
    @user = User.admins.first
    @project = project || create_vsm_project!
    @group = @project.group.root_ancestor
  end

  def seed!
    puts 'Seed aborted. Project does not belong to a group.' unless project.group
    puts 'Seed aborted. Project does not have a repository.' unless project.repository_exists?

    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        create_developers!
        create_stages!

        seed_group_labels!
        seed_issue_based_stages!
        seed_issue_label_based_stages!

        if Gitlab.ee?
          travel_back
          create_value_stream_aggregation(project.group)
          Gitlab::Seeder::DoraMetrics.new(project: project).execute
        end
      end

      seed_merge_request_based_stages!

      puts "."
      puts "Successfully seeded '#{group.full_path}' group for Custom Value Stream Management!"
      puts "URL: #{Rails.application.routes.url_helpers.group_url(group)}"
    end
  end

  private

  def in_dev_label
    @in_dev_label ||= GroupLabel.where(title: 'in-dev', group: group).first_or_create!
  end

  def in_review_label
    @in_review_label ||= GroupLabel.where(title: 'in-review', group: group).first_or_create!
  end

  def create_stages!
    stages_params = [
      {
        name: 'IssueCreated-IssueClosed',
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_closed
      },
      {
        name: 'IssueCreated-IssueFirstMentionedInCommit',
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_first_mentioned_in_commit
      },
      {
        name: 'IssueCreated-IssueInDevLabelAdded',
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_label_added,
        end_event_label_id: in_dev_label.id
      },
      {
        name: 'IssueInDevLabelAdded-IssueInReviewLabelAdded',
        start_event_identifier: :issue_label_added,
        start_event_label_id: in_dev_label.id,
        end_event_identifier: :issue_label_added,
        end_event_label_id: in_review_label.id
      },
      {
        name: 'MergeRequestCreated-MergeRequestClosed',
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_closed
      },
      {
        name: 'MergeRequestCreated-MergeRequestMerged',
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged
      }
    ]

    [project.project_namespace.reset, project.group].each do |parent|
      value_stream = create_custom_value_stream_for!(parent)

      stages_params.each do |params|
        next if ::Analytics::CycleAnalytics::Stage.where(namespace: parent).find_by(name: params[:name])

        ::Analytics::CycleAnalytics::Stage.create!(params.merge(namespace: parent, value_stream: value_stream))
      end
    end
  end

  def seed_group_labels!
    GROUP_LABEL_COUNT.times do
      label_title = FFaker::Product.brand
      label_color = ::Gitlab::Color.color_for(label_title).to_s

      Labels::CreateService
        .new(title: label_title, color: label_color)
        .execute(group: @group)
    end
  end

  def seed_issue_based_stages!
    issues.each do |issue|
      created_at = get_date_after(DAYS_BACK.days.ago)
      issue.update!(created_at: created_at)
    end

    # issues closed
    issues.pop(3).each do |issue|
      travel_to(get_date_after(issue.created_at))
      issue.close!
    end

    # issue first mentioned in commit and closed
    issues.pop(8).each do |issue|
      travel_to(get_date_after(issue.created_at))
      issue.metrics.update!(first_mentioned_in_commit_at: Time.now)
      travel_to(get_date_after(issue.metrics.first_mentioned_in_commit_at))
      issue.close!
    end
  end

  def seed_issue_label_based_stages!
    issues.pop(7).each do |issue|
      travel_to(get_date_after(issue.created_at))
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [in_dev_label.id] }
      ).execute(issue)

      travel_to(get_date_after(issue.updated_at))
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [in_review_label.id] }
      ).execute(issue)
    end
  end

  def seed_merge_request_based_stages!
    # Closed MRs
    merge_requests.pop(5).each do |mr|
      travel_to(get_date_after(mr.created_at))
      MergeRequests::CloseService.new(project: project, current_user: user).execute(mr)
    end

    merge_requests.pop(5).each do |mr|
      travel_to(get_date_after(mr.created_at))
      mr.metrics.update!(merged_at: Time.now)
      MergeRequestsClosingIssues.create!(issue: project.issues.sample, merge_request: mr)
    end
  end

  def issues
    @issues ||= Array.new(ISSUE_COUNT).map do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignees: [project.team.users.sample]
      }

      issue =
        Issues::CreateService.new(
          container: @project,
          current_user: project.team.users.sample,
          params: issue_params,
          perform_spam_check: false
        ).execute[:issue]

      # Required because seeds run in a transaction and these are now
      # created in an `after_commit` hook.
      Issue::Metrics.record!(issue)

      issue
    end
  end

  def merge_requests
    @merge_requests ||= begin
      MERGE_REQUEST_COUNT.times do |i|
        merge_request = FactoryBot.create(
          :merge_request,
          target_project: project,
          source_project: project,
          source_branch: "#{i}-feature-branch",
          target_branch: 'master',
          author: project.team.users.sample,
          created_at: get_date_after(DAYS_BACK.days.ago)
        )

        # Required because seeds run in a transaction and these are now
        # created in an `after_commit` hook.
        merge_request.ensure_metrics!
      end

      project.merge_requests.to_a
    end
  end

  def create_vsm_project!
    namespace = FactoryBot.create(
      :group,
      name: "Value Stream Management Group #{suffix}",
      path: "vsmg-#{suffix}"
    )
    project = FactoryBot.create(
      :project,
      :repository,
      name: "Value Stream Management Project #{suffix}",
      path: "vsmp-#{suffix}",
      creator: user,
      namespace: namespace
    )

    project.create_repository
    project
  end

  def create_custom_value_stream_for!(parent)
    Analytics::CycleAnalytics::ValueStreams::CreateService.new(
      current_user: user,
      namespace: parent,
      params: { name: "vs #{suffix}" }
    ).execute.payload[:value_stream]
  end

  def create_developers!
    5.times do |i|
      developer = FactoryBot.create(
        :user,
        name: "VSM User#{i}",
        username: "vsm-user-#{i}-#{suffix}",
        email: "vsm-user-#{i}@#{suffix}.com"
      )

      project.group&.add_developer(developer)
      project.add_developer(developer)
    end

    project.group&.add_developer(user)

    AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
  end

  def suffix
    @suffix ||= Time.now.to_i
  end

  def get_date_after(created_at)
    travel_back

    random_date = [*created_at.to_i..Time.now.to_i].sample

    Time.at(random_date)
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_CUSTOMIZABLE_CYCLE_ANALYTICS'
  project_id = ENV['VSA_SEED_PROJECT_ID']
  project = Project.find(project_id) if project_id

  if ENV[flag]
    seeder = Gitlab::Seeder::CustomizableCycleAnalytics.new(project)
    seeder.seed!
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
