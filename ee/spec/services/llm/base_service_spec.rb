# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::BaseService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
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

  context 'when user has no access' do
    it_behaves_like 'returns an error'
  end

  context 'when user has access' do
    before do
      project.add_guest(user)
    end

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

      it 'raises a NotImplementedError' do
        expect { subject.execute }.to raise_error(NotImplementedError)
      end
    end

    it 'raises a NotImplementedError' do
      expect { subject.execute }.to raise_error(NotImplementedError)
    end
  end
end
