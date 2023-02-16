# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require 'active_support/testing/time_helpers'

class Gitlab::Seeder::CustomizableCycleAnalytics
  include ActiveSupport::Testing::TimeHelpers

  attr_reader :project, :group, :user

  ONE_WEEK_IN_HOURS = 168
  ISSUE_COUNT = 15
  MERGE_REQUEST_COUNT = 10
  GROUP_LABEL_COUNT = 10

  def initialize(project)
    @project = project
    @group = project.group.root_ancestor
    @user = User.admins.first
  end

  def seed!
    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        create_stages!

        seed_group_labels!
        seed_issue_based_stages!
        seed_issue_label_based_stages!

        seed_merge_request_based_stages!

        puts "."
      end
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

    value_stream = ::Analytics::CycleAnalytics::ValueStream.create!(namespace: group, name: 'Test Value Stream')
    stages_params.each do |params|
      next if ::Analytics::CycleAnalytics::Stage.where(namespace: group).find_by(name: params[:name])

      ::Analytics::CycleAnalytics::Stage.create!(params.merge(namespace: group, value_stream: value_stream))
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
    # issue created - issue closed
    issues.pop(5).each do |issue|
      travel_to(random_duration_in_hours.hours.ago)
      issue.update!(created_at: Time.now)

      travel_to(random_duration_in_hours.hours.from_now)
      issue.close!
    end

    # issue created - issue first mentioned in commit
    issues.pop(5).each do |issue|
      travel_to(random_duration_in_hours.hours.ago)
      issue.update!(created_at: Time.now)

      travel_to(random_duration_in_hours.hours.from_now)
      issue.metrics&.update!(first_mentioned_in_commit_at: Time.now)
    end
  end

  def seed_issue_label_based_stages!
    issues.pop(5).each do |issue|
      travel_to(issue.created_at + random_duration_in_hours.hours)
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [in_dev_label.id] },
        spam_params: nil
      ).execute(issue)

      travel_to(random_duration_in_hours.hours.from_now)
      Issues::UpdateService.new(
        container: project,
        current_user: user,
        params: { label_ids: [in_review_label.id] },
        spam_params: nil
      ).execute(issue)
    end
  end

  def seed_merge_request_based_stages!
    merge_requests.pop(5).each do |mr|
      travel_to(random_duration_in_hours.hours.ago)
      mr.update!(created_at: Time.now)

      travel_to(random_duration_in_hours.hours.from_now)
      mr.close!
    end

    merge_requests.pop(5).each do |mr|
      travel_to(random_duration_in_hours.hours.ago)
      mr.update!(created_at: Time.now)

      travel_to(random_duration_in_hours.hours.from_now)
      mr.metrics&.update!(merged_at: Time.now)
    end
  end

  def random_duration_in_hours
    rand(ONE_WEEK_IN_HOURS)
  end

  def issues
    @issues ||= Array.new(ISSUE_COUNT).map do
      issue_params = {
        title: FFaker::Lorem.sentence(6),
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignees: [project.team.users.sample]
      }

      Issues::CreateService.new(container: @project, current_user: project.team.users.sample, params: issue_params, spam_params: nil).execute[:issue]
    end
  end

  def merge_requests
    @merge_requests ||= Array.new(MERGE_REQUEST_COUNT).map do |i|
      opts = {
        title: 'Customized Value Stream Analytics merge_request',
        description: "some description",
        source_branch: "#{FFaker::Lorem.word}-#{i}-#{SecureRandom.hex(5)}",
        target_branch: 'master'
      }

      begin
        developer = project.team.developers.sample
        MergeRequests::CreateService.new(project: project, current_user: developer, params: opts).execute
      rescue Gitlab::Access::AccessDeniedError
        nil
      end
    end.compact
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_CUSTOMIZABLE_CYCLE_ANALYTICS'
  project_id = ENV['VSA_SEED_PROJECT_ID']
  projects = project_id ? [Project.find(project_id)] : Project.find_each

  if ENV[flag]
    projects.each do |project|
      next unless project.group
      # This seed naively assumes that every project has a repository, and every
      # repository has a `master` branch, which may be the case for a pristine
      # GDK seed, but is almost never true for a GDK that's actually had
      # development performed on it.
      next unless project.repository_exists?
      next unless project.repository.commit('master')

      seeder = Gitlab::Seeder::CustomizableCycleAnalytics.new(project)
      seeder.seed!
    end
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
