# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::BaseService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:resource) { create(:issue, project: project) }
  let(:options) { {} }

  subject { described_class.new(user, resource, options) }

  shared_examples 'returns an error' do
    it 'returns an error' do
      result = subject.execute

      expect(result).to be_error
      expect(result.message).to eq(described_class::INVALID_MESSAGE)
    end
  end

  shared_examples 'raises a NotImplementedError' do
    it 'raises a NotImplementedError' do
      expect { subject.execute }.to raise_error(NotImplementedError)
    end
  end

  context 'when user has no access' do
    it_behaves_like 'returns an error'
  end

  context 'when user has access' do
    before do
      project.add_guest(user)
    end

    it_behaves_like 'raises a NotImplementedError'

    context 'when ai integration is not enabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it_behaves_like 'returns an error'
    end

    context 'when resource should not be sent to AI' do
      let_it_be(:project) { create(:project, :private) }

      it_behaves_like 'returns an error'
    end

    context 'when resource does not have a resource parent' do
      let_it_be(:resource) { user }

      it_behaves_like 'raises a NotImplementedError'
    end

    context 'when resource is a user' do
      let_it_be(:resource) { user }

      context 'on Gitlab.com', :saas do
        let_it_be_with_reload(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }

        before do
          allow(ultimate_group.namespace_settings).to receive(:ai_settings_allowed?).and_return(true)
          allow(Gitlab).to receive(:com?).and_return(true)
        end

        it_behaves_like 'returns an error'

        context 'when the user belongs to a group with an ultimate plan' do
          before do
            ultimate_group.add_developer(user)
          end

          context 'when the group has third party AI features enabled' do
            before do
              ultimate_group.namespace_settings.update!(third_party_ai_features_enabled: true)
            end

            it_behaves_like 'raises a NotImplementedError'
          end

          context 'when the group does not have third party AI features enabled' do
            before do
              ultimate_group.namespace_settings.update!(third_party_ai_features_enabled: false)
            end

            it_behaves_like 'returns an error'
          end
        end
      end
    end
  end
end
