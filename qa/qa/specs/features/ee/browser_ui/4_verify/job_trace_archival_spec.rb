# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :orchestrated, :runner, :requires_admin, :geo do
    describe 'When CI job trace is archived and geo is enabled' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:pipeline_job_name) { 'test-archivals' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'geo-project-with-archived-traces'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it 'continues to display the archived trace', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/357771' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  #{pipeline_job_name}:
                    tags:
                      - '#{executor}'
                    script:
                    - echo 'OK!'
                YAML
              }
            ]
          )
        end.project.visit!

        Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'completed')

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job("#{pipeline_job_name}")
        end

        job_id = current_url.split('/')[-1].to_i
        job = QA::Resource::Job.initialize(job_id, project)
        puts "ARTIFACTS -=-=-=-=-=-=-"
        puts job.artifacts
      end
    end
  end
end
