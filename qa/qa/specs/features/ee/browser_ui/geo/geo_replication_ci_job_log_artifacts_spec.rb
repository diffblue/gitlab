# frozen_string_literal: true

module QA
  RSpec.describe 'Geo', :orchestrated, :runner, :requires_admin, :geo do
    describe 'CI job' do
      before(:all) do
        @file_name = 'geo_artifact.txt'
        @directory_name = 'geo_artifacts'
        @pipeline_job_name = 'test-artifacts'
        executor = "qa-runner-#{Time.now.to_i}"

        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'geo-project-with-artifacts'
        end

        @runner = Resource::Runner.fabricate! do |runner|
          runner.project = @project
          runner.name = executor
          runner.tags = [executor]
        end

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = @project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  test-artifacts:
                    tags:
                      - '#{executor}'
                    artifacts:
                      paths:
                        - '#{@directory_name}'
                      expire_in: 1000 seconds
                    script:
                      - |
                        mkdir #{@directory_name}
                        echo "CONTENTS" > #{@directory_name}/#{@file_name}
                YAML
              }
            ]
          )
        end
      end

      after(:all) do
        @runner.remove_via_api!
      end

      # Test code is based on qa/specs/features/browser_ui/4_verify/locked_artifacts_spec.rb
      it 'replicates the job log to the secondary Geo site', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1653' do
        Runtime::Logger.debug('Visiting the secondary Geo site')

        Flow::Login.while_signed_in(address: :geo_secondary) do
          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(@project.name)
            dashboard.go_to_project(@project.name)
          end

          Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'replicated')

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.wait_for_pipeline_job_replication(@pipeline_job_name)
            pipeline.click_job(@pipeline_job_name)
          end

          Page::Project::Job::Show.perform do |pipeline_job|
            pipeline_job.wait_for_job_log_replication
            expect(pipeline_job).to have_job_log
          end
        end
      end

      it 'replicates the job artifact to the secondary Geo site', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/quality/test_cases/1658' do
        Runtime::Logger.debug('Visiting the secondary Geo site')

        Flow::Login.while_signed_in(address: :geo_secondary) do
          EE::Page::Main::Banner.perform do |banner|
            expect(banner).to have_secondary_read_only_banner
          end

          Page::Main::Menu.perform(&:go_to_projects)

          Page::Dashboard::Projects.perform do |dashboard|
            dashboard.wait_for_project_replication(@project.name)
            dashboard.go_to_project(@project.name)
          end

          Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'replicated')

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.wait_for_pipeline_job_replication(@pipeline_job_name)
            pipeline.click_job(@pipeline_job_name)
          end

          Page::Project::Job::Show.perform do |pipeline_job|
            pipeline_job.wait_for_job_artifact_replication
            pipeline_job.click_browse_button
          end

          Page::Project::Artifact::Show.perform do |artifact|
            artifact.go_to_directory(@directory_name)
            expect(artifact).to have_content(@file_name)
          end
        end
      end
    end
  end
end
