# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpstreamProjectsSubscriptionsCleanupWorker, feature_category: :continuous_integration do
  describe '#perform' do
    let(:group) { create(:group, :public) }
    let(:project) { create(:project, :repository, :public, group: group) }

    let_it_be(:project_2) { create(:project, :public) }

    before do
      project.upstream_project_subscriptions.create!(upstream_project: project_2)
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [project.id] }
    end

    context 'project does not exist' do
      it 'does nothing' do
        expect { described_class.new.perform(non_existing_record_id) }.not_to change { Ci::Subscriptions::Project.count }
      end
    end

    context 'ci_project_subscriptions licensed feature available' do
      before do
        stub_licensed_features(ci_project_subscriptions: true)
      end

      it 'does not delete the pipeline subscriptions' do
        expect { described_class.new.perform(project.id) }.not_to change { project.upstream_project_subscriptions.count }
      end
    end

    context 'ci_project_subscriptions licensed feature not available' do
      before do
        stub_licensed_features(ci_project_subscriptions: false)
      end

      it 'deletes the upstream subscriptions' do
        expect { described_class.new.perform(project.id) }.to change { project.upstream_project_subscriptions.count }.from(1).to(0)
          .and change { project_2.downstream_project_subscriptions.count }.from(1).to(0)
      end
    end
  end
end
