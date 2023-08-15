# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require 'active_support/testing/time_helpers'

# Usage:
#
# Simple invocation seeds all projects:
#
# FILTER=productivity_analytics SEED_PRODUCTIVITY_ANALYTICS=1 bundle exec rake db:seed_fu
#
# Seed specific project:
#
# FILTER=productivity_analytics SEED_PRODUCTIVITY_ANALYTICS=1 PROJECT_ID=10 bundle exec rake db:seed_fu

class Gitlab::Seeder::ProductivityAnalytics
  include ActiveSupport::Testing::TimeHelpers

  attr_reader :project, :maintainers, :admin, :default_branch

  def initialize(project)
    @admin = User.admins.first
    @project = project || create_project_with_group
    @issue_count = 10
    @maintainers = []
    @default_branch = @project.default_branch
  end

  def seed!
    unless project.repository_exists?
      error =
        "(#{project.full_path}) doesn't have a repository." \
        'Try specifying a project with working repository or omit the PROJECT_ID parameter' \
        'so the seed script will automatically create one.'
    end

    if Gitlab.config.external_diffs.enabled
      error =
        "(#{project.full_path}) has merge request external diffs enabled." \
        'Disable it before continuing.'
    end

    if error
      print_error(error)

      return
    end

    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        create_maintainers!
        print '.'

        issues = create_issues
        print '.'

        add_milestones_and_list_labels(issues)
        print '.'

        branches = mention_in_commits(issues)
        print '.'

        merge_requests = create_merge_requests_closing_issues(issues, branches)
        print '.'

        create_notes(merge_requests)
        print '.'
      end
    end

    merge_merge_requests
    print '.'

    puts "\nSuccessfully seeded '#{project.full_path}'\n"
    puts "URL: #{Rails.application.routes.url_helpers.project_url(project)}"
  end

  private

  def print_error(message)
    puts 'WARNING'
    puts '========================'
    puts "Seeding #{self.class} is not possible\n"
    puts message
  end

  def create_project_with_group
    Sidekiq::Testing.inline! do
      namespace = FactoryBot.create(
        :group,
        :public,
        name: "Productivity Group #{suffix}",
        path: "p-analytics-group-#{suffix}"
      )
      project = FactoryBot.create(
        :project,
        :public,
        :repository,
        name: "Productivity Project #{suffix}",
        path: "p-analytics-project-#{suffix}",
        creator: admin,
        namespace: namespace
      )

      project.create_repository
      project
    end
  end

  def create_maintainers!
    5.times do |i|
      user = FactoryBot.create(
        :user,
        name: "P User#{i}",
        username: "p-user-#{i}-#{suffix}",
        email: "p-user-#{i}@#{suffix}.com"
      )

      project.group&.add_maintainer(user)
      project.add_maintainer(user)

      @maintainers << user
    end

    AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute

    # Persist project and namespace on DB so gitaly allows users creating branches in repository
    Project.connection.commit_db_transaction
    Project.connection.begin_db_transaction
  end

  def create_issues
    Array.new(@issue_count) do
      issue_params = {
        title: "Productivity Analytics: #{FFaker::Lorem.sentence(6)}",
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignees: [project.team.users.sample]
      }

      travel_to(random_past_date) do
        Issues::CreateService.new(container: project, current_user: maintainers.sample, params: issue_params, perform_spam_check: false).execute[:issue]
      end
    end
  end

  def add_milestones_and_list_labels(issues)
    issues.shuffle.map.with_index do |issue, index|
      travel_to(random_past_date) do
        if index.even?
          issue.update(milestone: project.milestones.sample)
        else
          label_name = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"
          list_label = FactoryBot.create(:label, title: label_name, project: issue.project)
          FactoryBot.create(:list, board: FactoryBot.create(:board, project: issue.project), label: list_label)
          issue.update(labels: [list_label])
        end

        issue
      end
    end
  end

  def mention_in_commits(issues)
    issues.map do |issue|
      branch_name = filename = "#{FFaker::Product.brand}-#{FFaker::Product.brand}-#{rand(1000)}"

      travel_to(random_past_date) do
        commit_user = maintainers.sample
        issue.project.repository.add_branch(commit_user, branch_name, 'HEAD')

        commit_sha = issue.project.repository.create_file(commit_user, filename, 'content', message: "Commit for #{issue.to_reference}", branch_name: branch_name)
        issue.project.repository.commit(commit_sha)

        ::Git::BranchPushService.new(
          issue.project,
          commit_user,
          change: {
            oldrev: issue.project.repository.commit('HEAD').sha,
            newrev: commit_sha,
            ref: "refs/heads/#{default_branch}"
          }
        ).execute
      end

      branch_name
    end
  end

  def create_merge_requests_closing_issues(issues, branches)
    issues.zip(branches).map do |issue, branch|
      opts = {
        title: 'Productivity Analytics merge_request',
        description: "Fixes #{issue.to_reference}",
        source_branch: branch,
        target_branch: default_branch
      }
      travel_to(issue.created_at) do
        mr = MergeRequests::CreateService.new(project: issue.project, current_user: maintainers.sample, params: opts).execute
        mr.ensure_metrics!
        mr.prepare
        mr
      end
    end
  end

  def create_notes(merge_requests)
    merge_requests.each do |merge_request|
      date = get_date_after(merge_request.created_at)
      travel_to(date) do
        Note.create!(
          author: maintainers.sample,
          project: merge_request.project,
          noteable: merge_request,
          note: FFaker::Lorem.sentence(rand(5))
        )
      end
    end
  end

  def merge_merge_requests
    Sidekiq::Worker.skipping_transaction_check do
      project.merge_requests.take(7).each do |merge_request| # leaves some MRs opened for code review analytics chart
        date = get_date_after(merge_request.created_at)
        user = maintainers.sample
        travel_to(date) do
          MergeRequests::MergeService.new(
            project: merge_request.project,
            current_user: user,
            params: { sha: merge_request.diff_head_sha }
          ).execute(merge_request.reset)

          issue = merge_request.visible_closing_issues_for(user).first
          MergeRequests::CloseIssueWorker.new.perform(project.id, user.id, issue.id, merge_request.id) if issue
        end
      end
    end
  end

  def suffix
    @suffix ||= Time.now.to_i
  end

  def get_date_after(date)
    travel_back

    random_date = [*date.to_i..Time.now.to_i].sample

    Time.at(random_date)
  end

  def random_past_date
    rand(1..45).days.ago
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_PRODUCTIVITY_ANALYTICS'
  project_id = ENV['PROJECT_ID']

  project = Project.find(project_id) if project_id

  if ENV[flag]
    seeder = Gitlab::Seeder::ProductivityAnalytics.new(project)
    seeder.seed!
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
