# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', product_group: :compliance do
    describe 'Compliance pipeline' do
      let(:group) do
        create(:group, path: "compliance-pipeline-#{Faker::Alphanumeric.alphanumeric(number: 8)}")
      end

      let!(:runner) do
        Resource::GroupRunner.fabricate_via_api! do |runner|
          runner.group = group
          runner.name = runner_name
          runner.tags = [runner_name]
        end
      end

      let(:runner_name) { "runner-for-#{group.name}" }

      context 'when a compliance framework has a compliance pipeline' do
        let(:pipeline_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'pipeline-project'
            project.group = group
          end
        end

        let(:compliance_framework) do
          QA::EE::Resource::ComplianceFramework.fabricate_via_api! do |framework|
            framework.group = group
            framework.pipeline_configuration_full_path = ".compliance-ci.yml@#{pipeline_project.full_path}"
          end
        end

        let(:compliance_job_name) { 'comply' }

        before do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = pipeline_project
            commit.commit_message = 'Add .compliance-ci.yml'
            commit.add_files([{
              file_path: '.compliance-ci.yml',
              content: <<~YAML
                #{compliance_job_name}:
                  tags:
                    - #{runner_name}
                  script: echo "resistance is futile"
              YAML
            }])
          end
        end

        after do
          # Not removed by TestResourcesHandler because it doesn't yet handle GraphQL resources
          compliance_framework.remove_via_api!(delete_default: true)
        end

        it('runs that pipeline in a different project that has the compliance framework assigned',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/413715'
        ) do
          compliant_project = Resource::Project.fabricate_via_api! do |project|
            project.name = 'compliant-project'
            project.group = group
          end
          compliant_project.compliance_framework = compliance_framework

          mr = Resource::MergeRequest.fabricate_via_api! do |merge_request|
            merge_request.project = compliant_project
          end

          pipeline = compliant_project.wait_for_pipeline(ref: mr.source_branch, status: 'success')
          expect(pipeline).not_to be_nil,
            "Expected pipeline with ref #{mr.source_branch} to succeed." \
            "Project pipelines were: #{compliant_project.pipelines}"

          pipeline_resource = Resource::Pipeline.init do |p|
            p.project = compliant_project
            p.id = pipeline[:id]
          end

          expect(pipeline_resource.jobs.first[:name]).to eq(compliance_job_name)
        end
      end
    end
  end
end
