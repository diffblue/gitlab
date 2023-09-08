# frozen_string_literal: true

namespace :gitlab do
  namespace :seed do
    namespace :merge_trains do
      desc 'Seed a project with merge trains configured and some MRs'
      task project: :gitlab_environment do |_t, _args|
        MergeTrains::SeedProject.new.execute
      end
    end
  end
end

module MergeTrains
  class SeedProject
    NUMBER_OF_MRS = 20
    NUMBER_OF_COMMITS_PER_MR = 3
    CI_YML = <<-YML
    job1:
      script:
        - echo "This job runs in merge request pipelines"
      rules:
        - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
    YML

    def execute
      user = User.first
      project = create_project_with_ci_config(user)

      1.upto(NUMBER_OF_MRS) do |mr_number|
        branch_name = create_branch(user, project, mr_number)
        create_commits(user, project, branch_name, mr_number)
        Sidekiq::Worker.skipping_transaction_check do
          MergeRequests::CreateService.new(
            project: project,
            current_user: user,
            params: { source_branch: branch_name, target_branch: Gitlab::DefaultBranch.value,
                      title: "MR #: #{mr_number}" }
          ).execute
        end
      end

      puts "Created project #{project.name} with #{NUMBER_OF_MRS} MRs"
    end

    def create_project_with_ci_config(user)
      project = ::Projects::CreateService.new(
        user,
        { name: "merge-trains-#{SecureRandom.uuid}", namespace_id: Namespace.first.id }
      ).execute

      project.merge_pipelines_enabled = true
      project.merge_trains_enabled = true
      project.save!

      project.repository.create_file(user, '.gitlab-ci.yml', CI_YML, branch_name: Gitlab::DefaultBranch.value,
        message: 'Add Merged result CI config')

      project
    end

    def create_branch(user, project, mr_number)
      branch_name = "#{mr_number}-#{SecureRandom.uuid}"
      project.repository.add_branch(user, branch_name, project.default_branch_or_main, expire_cache: true)

      branch_name
    end

    def create_a_file_with_commit(user, project, branch_name, mr_number, commit_number)
      file_name = "index_#{mr_number}_uuid_#{SecureRandom.uuid}"
      file_content = "random uuid: #{SecureRandom.uuid}, index: #{mr_number}, created_at: #{Time.zone.now}"
      project.repository.create_file(user, file_name, file_content, branch_name: branch_name,
        message: "commit #: #{commit_number}, MR #: #{mr_number}")
    end

    def create_commits(user, project, branch_name, mr_number)
      1.upto(NUMBER_OF_COMMITS_PER_MR) do |commit_number|
        create_a_file_with_commit(user, project, branch_name, mr_number, commit_number)
      end
    end
  end
end
