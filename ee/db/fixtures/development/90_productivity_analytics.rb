# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require 'active_support/testing/time_helpers'

class Gitlab::Seeder::ProductivityAnalytics
  include ActiveSupport::Testing::TimeHelpers

  def initialize(project)
    @project = project
    @user = User.admins.first
    @issue_count = 3
  end

  def seed!
    Sidekiq::Worker.skipping_transaction_check do
      Sidekiq::Testing.inline! do
        issues = create_issues
        print '.'

        add_milestones_and_list_labels(issues)
        print '.'

        branches = mention_in_commits(issues)
        print '.'

        merge_requests = create_merge_requests_closing_issues(issues, branches)
        print '.'

        create_notes(merge_requests)

        merge_merge_requests(merge_requests)
        print '.'
      end
    end

    print '.'
  end

  private

  def create_issues
    Array.new(@issue_count) do
      issue_params = {
        title: "Productivity Analytics: #{FFaker::Lorem.sentence(6)}",
        description: FFaker::Lorem.sentence,
        state: 'opened',
        assignees: [@project.team.users.sample]
      }

      travel_to(rand(90..100).days.ago) do
        Issues::CreateService.new(container: @project, current_user: @project.team.users.sample, params: issue_params, spam_params: nil).execute[:issue]
      end
    end
  end

  def add_milestones_and_list_labels(issues)
    issues.shuffle.map.with_index do |issue, index|
      travel_to(80.days.ago) do
        if index.even?
          issue.update(milestone: @project.milestones.sample)
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

      travel_to(70.days.ago) do
        issue.project.repository.add_branch(@user, branch_name, 'master')

        commit_sha = issue.project.repository.create_file(@user, filename, "content", message: "Commit for #{issue.to_reference}", branch_name: branch_name)
        issue.project.repository.commit(commit_sha)

        ::Git::BranchPushService.new(
          issue.project,
          @user,
          change: {
            oldrev: issue.project.repository.commit("master").sha,
            newrev: commit_sha,
            ref: 'refs/heads/master'
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
        target_branch: 'master'
      }
      travel_to(issue.created_at) do
        MergeRequests::CreateService.new(project: issue.project, current_user: @user, params: opts).execute
      end
    end
  end

  def create_notes(merge_requests)
    merge_requests.each do |merge_request|
      travel_to(merge_request.created_at + rand(5).days) do
        Note.create!(
          author: @user,
          project: merge_request.project,
          noteable: merge_request,
          note: FFaker::Lorem.sentence(rand(5))
        )
      end
    end
  end

  def merge_merge_requests(merge_requests)
    merge_requests.each do |merge_request|
      travel_to(rand(30..45).days.ago) do
        MergeRequests::MergeService.new(project: merge_request.project, current_user: @user).execute(merge_request)
      end
    end
  end
end

Gitlab::Seeder.quiet do
  flag = 'SEED_PRODUCTIVITY_ANALYTICS'

  if ENV[flag]
    Project.not_mass_generated.find_each do |project|
      # This seed naively assumes that every project has a repository, and every
      # repository has a `master` branch, which may be the case for a pristine
      # GDK seed, but is almost never true for a GDK that's actually had
      # development performed on it.
      next unless project.repository_exists? && project.repository.commit('master')

      seeder = Gitlab::Seeder::ProductivityAnalytics.new(project)
      seeder.seed!
      puts "Productivity analytics seeded for project #{project.full_path}"
      break
    end
  else
    puts "Skipped. Use the `#{flag}` environment variable to enable."
  end
end
