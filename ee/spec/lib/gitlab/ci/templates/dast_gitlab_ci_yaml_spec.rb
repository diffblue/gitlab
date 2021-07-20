# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DAST.gitlab-ci.yml' do
  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('DAST') }

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
        it 'includes no jobs' do
          expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
        end
      end

      context 'when project has Ultimate license' do
        let(:license) { build(:license, plan: License::ULTIMATE_PLAN) }
        let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }

        before do
          allow(License).to receive(:current).and_return(license)
        end

        context 'by default' do
          before do
            allow(cluster).to receive(:active?).and_return(true)
          end

          it 'includes job' do
            expect(build_names).to match_array(%w[dast])
          end
        end

        context 'when cluster is not active' do
          context 'by default' do
            it 'includes dast job' do
              expect(build_names).to match_array(%w[dast])
            end
          end
        end

        context 'when DAST_DISABLED=1' do
          before do
            allow(cluster).to receive(:active?).and_return(true)

            create(:ci_variable, project: project, key: 'DAST_DISABLED', value: '1')
          end

          it 'includes no jobs' do
            expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
          end
        end

        context 'when DAST_DISABLED_FOR_DEFAULT_BRANCH=1' do
          before do
            allow(cluster).to receive(:active?).and_return(true)

            create(:ci_variable, project: project, key: 'DAST_DISABLED_FOR_DEFAULT_BRANCH', value: '1')
          end

          context 'when on default branch' do
            it 'includes no jobs' do
              expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
            end
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
            it 'includes dast job' do
              expect(build_names).to match_array(%w[dast])
            end
          end

          context 'when on feature branch' do
            let(:pipeline_branch) { 'patch-1' }

            before do
              project.repository.create_branch(pipeline_branch, default_branch)
            end

            it 'includes no jobs' do
              expect { pipeline }.to raise_error(Ci::CreatePipelineService::CreateError)
            end
          end
        end
      end
    end
  end
end
