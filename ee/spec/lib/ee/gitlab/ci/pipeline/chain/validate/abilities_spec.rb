# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::Abilities, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) do
    build_stubbed(:ci_pipeline, project: project)
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command
      .new(project: project, current_user: user, origin_ref: ref)
  end

  let(:step) { described_class.new(pipeline, command) }
  let(:ref) { 'master' }

  describe '#perform!' do
    before do
      project.add_developer(user)
    end

    context 'when triggering builds for project mirrors is disabled' do
      it 'returns an error' do
        allow(command)
          .to receive(:allow_mirror_update)
          .and_return(true)

        allow(project)
          .to receive(:mirror_trigger_builds?)
          .and_return(false)

        step.perform!

        expect(pipeline.errors.to_a)
          .to include('Pipeline is disabled for mirror updates')
      end
    end

    context 'when the maintainer is blocked by IP restriction' do
      # Project must belong to a group to use IP restriction
      let_it_be(:project) { create(:project, :in_group) }

      before do
        allow_next_instance_of(Gitlab::IpRestriction::Enforcer) do |enforcer|
          allow(enforcer).to receive(:allows_current_ip?).and_return(false)
        end

        step.perform!
      end

      it 'adds an error about insufficient permissions' do
        expect(pipeline.errors.to_a)
          .to include(/Insufficient permissions/)
      end

      it 'breaks the pipeline builder chain' do
        expect(step.break?).to eq true
      end
    end
  end
end
