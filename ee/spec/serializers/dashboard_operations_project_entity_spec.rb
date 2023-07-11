# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DashboardOperationsProjectEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:resource) { Dashboard::Operations::ListService::DashboardProject.new(project, nil, 0) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  context 'the project supports the ops dashboard' do
    before do
      stub_licensed_features(operations_dashboard: true)
    end

    it 'has all required fields' do
      expect(subject).to include(:remove_path, :alert_count, :upgrade_required)
      expect(subject.first).to include(:id)
    end

    it 'does not have optional fields' do
      expect(subject).not_to include(:last_pipeline, :upstream_pipeline, :downstream_pipelines, :upgrade_path)
    end

    context 'when there is a pipeline' do
      let!(:pipeline) { create(:ci_pipeline, project: project, sha: project.commit.sha) }

      it 'has the last pipeline field' do
        expect(subject).to include(:last_pipeline)
      end

      context 'when there is an upstream status' do
        let(:bridge) { create(:ci_bridge, status: :pending) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge)
        end

        it 'has the triggered_by pipeline field' do
          expect(subject[:last_pipeline]).to include(:triggered_by)
        end
      end

      context 'when there is a downstream status' do
        let(:build) { create(:ci_build, pipeline: pipeline) }

        before do
          create(:ci_sources_pipeline, source_job: build)
        end

        it 'has the triggered pipeline field' do
          expect(subject[:last_pipeline]).to include(:triggered)
        end

        context 'when there are multiple downstream statuses' do
          before do
            create_list(:ci_sources_pipeline, 5, source_job: build)
          end

          it 'has the downstream pipeline field' do
            expect(subject[:last_pipeline]).to include(:triggered)
            expect(subject[:last_pipeline][:triggered].count).to eq(6)
          end
        end
      end

      context 'when there are both an upstream and downstream pipelines' do
        let(:build) { create(:ci_build, pipeline: pipeline) }
        let(:bridge) { create(:ci_bridge, status: :pending) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge)
          create_list(:ci_sources_pipeline, 5, source_job: build)
        end

        it 'has the upstream pipeline field' do
          expect(subject[:last_pipeline]).to include(:triggered_by)
        end

        it 'has the downstream pipeline field' do
          expect(subject[:last_pipeline]).to include(:triggered)
          expect(subject[:last_pipeline][:triggered].count).to eq(5)
        end
      end
    end
  end

  context 'the project does not support the ops dashboard' do
    it 'has the expected fields' do
      expect(subject).to include(:remove_path, :upgrade_required)
      expect(subject.first).to include(:id)

      expect(subject).not_to include(:alert_count, :upgrade_path)
    end

    context 'the user has permission to upgrade plan', :enable_admin_mode do
      let(:user) { build(:user, :admin) }

      it 'shows the profile upgrade path' do
        expect(subject[:upgrade_path]).to eq '/-/profile/billings'
      end
    end

    context 'the user has permission to upgrade group', :enable_admin_mode do
      let(:project) { build(:project, namespace: create(:group)) }
      let(:user) { build(:user, :admin) }

      it 'shows the group upgrade path' do
        expect(subject[:upgrade_path]).to eq "/groups/#{project.namespace.path}/-/billings"
      end
    end
  end
end
