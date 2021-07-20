# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'includes no jobs' do
  it 'includes no jobs' do
    expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError, 'No stages / jobs for this pipeline.')
  end
end

RSpec.shared_examples 'includes dast job' do
  it 'includes dast job' do
    expect(build_names).to match_array(%w[dast])
  end
end

RSpec.describe 'DAST.latest.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST.latest') }

  describe 'the created pipeline' do
    let(:default_branch) { project.default_branch_or_main }
    let(:pipeline_branch) { default_branch }
    let(:project) { create(:project, :custom_repo, files: { 'README.txt' => '' }) }
    let(:user) { project.owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_branch ) }
    let(:pipeline) { service.execute!(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }
    let(:ci_pipeline_yaml) { "stages: [\"dast\"]\n" }

    specify { expect(template).not_to be_nil }

    context 'when ci yaml is just template' do
      before do
        stub_ci_pipeline_yaml_file(template.content)

        allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
          allow(worker).to receive(:perform).and_return(true)
        end

        allow(project).to receive(:default_branch).and_return(default_branch)
      end

      context 'when project has no license' do
        it 'includes no jobs' do
          expect(build_names).to be_empty
        end
      end
    end

    context 'when stages includes dast' do
      before do
        stub_ci_pipeline_yaml_file(ci_pipeline_yaml + template.content)

        allow_next_instance_of(Ci::BuildScheduleWorker) do |worker|
          allow(worker).to receive(:perform).and_return(true)
        end

        allow(project).to receive(:default_branch).and_return(default_branch)
      end

      context 'when project has no license' do
        include_examples 'includes no jobs'
      end

      context 'when project has cluster' do
        let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }

        context 'by default' do
          before do
            allow(cluster).to receive(:active?).and_return(true)
          end

          include_examples 'includes no jobs'
        end

        context 'when project has Ultimate license' do
          let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

          before do
            allow(License).to receive(:current).and_return(license)
            allow(cluster).to receive(:active?).and_return(true)
          end

          context 'when no specification provided' do
            include_examples 'includes dast job'
          end
        end
      end

      context 'when cluster is not active' do
        context 'by default' do
          include_examples 'includes no jobs'
        end

        context 'when DAST_WEBSITE is present' do
          before do
            create(:ci_variable, project: project, key: 'DAST_WEBSITE', value: 'http://example.com')
          end

          include_examples 'includes dast job'
        end

        context 'when DAST_API_SPECIFICATION is present' do
          before do
            create(:ci_variable, project: project, key: 'DAST_API_SPECIFICATION', value: 'http://my.api/api-specification.yml')
          end

          include_examples 'includes dast job'
        end

        context 'when project has Ultimate license' do
          let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }

          before do
            allow(License).to receive(:current).and_return(license)
          end

          context 'when project has cluster' do
            let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }

            context 'when DAST_DISABLED=1' do
              before do
                allow(cluster).to receive(:active?).and_return(true)

                create(:ci_variable, project: project, key: 'DAST_DISABLED', value: '1')
              end

              include_examples 'includes no jobs'
            end

            context 'when DAST_DISABLED_FOR_DEFAULT_BRANCH=1' do
              before do
                allow(cluster).to receive(:active?).and_return(true)

                create(:ci_variable, project: project, key: 'DAST_DISABLED_FOR_DEFAULT_BRANCH', value: '1')
              end

              context 'when on default branch' do
                include_examples 'includes no jobs'
              end

              context 'when on feature branch' do
                let(:pipeline_branch) { 'patch-1' }

                before do
                  project.repository.create_branch(pipeline_branch, default_branch)
                end

                it 'includes dast job' do
                  expect(build_names).to match_array(%w[dast])
                end
              end
            end

            context 'when REVIEW_DISABLED=true' do
              before do
                allow(cluster).to receive(:active?).and_return(true)

                create(:ci_variable, project: project, key: 'REVIEW_DISABLED', value: 'true')
              end

              context 'when on default branch' do
                include_examples 'includes dast job'
              end

              context 'when on feature branch' do
                let(:pipeline_branch) { 'patch-1' }

                before do
                  project.repository.create_branch(pipeline_branch, default_branch)
                end

                include_examples 'includes no jobs'
              end
            end
          end
        end
      end
    end
  end
end
