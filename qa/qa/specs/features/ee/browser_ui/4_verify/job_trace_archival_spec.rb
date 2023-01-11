# frozen_string_literal: true
module QA
  RSpec.describe 'Verify', :orchestrated, :runner, :requires_admin, :geo, product_group: :pipeline_execution do
    describe 'When CI job log is archived and geo is enabled' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:pipeline_job_name) { 'test-archival' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'geo-project-with-archived-traces'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  test-archival:
                    tags:
                      - #{executor}
                    script: echo "OK"
                YAML
              }
            ]
          )
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
        project.remove_via_api!
      end

      it(
        'continues to display the archived trace',
         testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/357771'
      ) do
        job = Resource::Job.fabricate_via_api! do |job|
          job.id = project.job_by_name(pipeline_job_name)[:id]
          job.name = pipeline_job_name
          job.project = project
        end

        job.visit!

        Support::Waiter.wait_until(max_duration: 150) do
          job.artifacts.any?
        end

        Page::Project::Job::Show.perform do |job|
          job.refresh
          expect(job).to have_job_log
        end
      end
    end
  end
end
