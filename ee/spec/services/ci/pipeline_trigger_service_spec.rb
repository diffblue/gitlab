# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineTriggerService do
  let_it_be(:project) { create(:project, :repository) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:result) { described_class.new(project, user, params).execute }

    before do
      project.add_developer(user)
    end

    shared_examples 'with ip restriction' do
      let_it_be_with_reload(:group) { create(:group, :public) }
      let_it_be_with_reload(:project) { create(:project, :repository, group: group) }

      before do
        allow(Gitlab::IpAddressState).to receive(:current).and_return('192.168.0.2')
        stub_licensed_features(group_ip_restriction: true)
      end

      context 'group with restriction' do
        before do
          create(:ip_restriction, group: group, range: range)
        end

        context 'address is within the range' do
          let(:range) { '192.168.0.0/24' }

          it 'triggers a pipeline' do
            expect { result }.to change { Ci::Pipeline.count }.by(1)
          end
        end

        context 'address is outside the range' do
          let(:range) { '10.0.0.0/8' }

          it 'does nothing' do
            expect { result }.not_to change { Ci::Pipeline.count }
          end
        end
      end

      context 'group without restriction' do
        it 'triggers a pipeline' do
          expect { result }.to change { Ci::Pipeline.count }.by(1)
        end
      end
    end

    context 'with a trigger token' do
      let(:params) { { token: trigger.token, ref: 'master', variables: nil } }

      let(:trigger) { create(:ci_trigger, project: project, owner: user) }

      include_examples 'with ip restriction'
    end

    context 'with a job token' do
      let!(:pipeline) { create(:ci_empty_pipeline, project: project) }
      let(:job) { create(:ci_build, :running, pipeline: pipeline, user: user) }
      let(:params) { { token: job.token, ref: 'master', variables: nil } }

      include_examples 'with ip restriction'
    end
  end
end
