# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::GraphHelper do
  let_it_be(:current_user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:project) { create(:project, :private) }

  let(:is_feature_licensed) { true }
  let(:is_user_authorized) { true }

  before do
    stub_licensed_features(dora4_analytics: is_feature_licensed)
    self.instance_variable_set(:@current_user, current_user)
  end

  describe '#should_render_dora_charts' do
    shared_examples 'returns true' do
      it { expect(should_render_dora_charts).to be(true) }
    end

    shared_examples 'returns false' do
      it { expect(should_render_dora_charts).to be(false) }
    end

    shared_examples '#should_render_dora_charts for a specific type of container' do
      it_behaves_like 'returns true'

      context 'when the feature is not available' do
        let(:is_feature_licensed) { false }

        it_behaves_like 'returns false'
      end

      context 'when the user does not have permission' do
        let(:is_user_authorized) { false }

        it_behaves_like 'returns false'
      end
    end

    context 'when serving the project-level DORA page' do
      before do
        self.instance_variable_set(:@project, project)
        allow(self).to receive(:can?).with(current_user, :read_dora4_analytics, project).and_return(is_user_authorized)
      end

      it_behaves_like '#should_render_dora_charts for a specific type of container'
    end

    context 'when serving the group-level DORA page' do
      before do
        self.instance_variable_set(:@group, group)
        allow(self).to receive(:can?).with(current_user, :read_dora4_analytics, group).and_return(is_user_authorized)
      end

      it_behaves_like '#should_render_dora_charts for a specific type of container'
    end
  end

  describe '#should_render_quality_summary' do
    subject { helper.should_render_quality_summary }

    before do
      self.instance_variable_set(:@project, project)
    end

    context 'when licensed feature is available' do
      before do
        stub_licensed_features(project_quality_summary: true)
      end

      context 'when feature flag is enabled' do
        it { is_expected.to eq(true) }
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(project_quality_summary_page: false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when licensed feature is not available' do
      before do
        stub_licensed_features(project_quality_summary: false)
      end

      it { is_expected.to eq(false) }
    end
  end
end
