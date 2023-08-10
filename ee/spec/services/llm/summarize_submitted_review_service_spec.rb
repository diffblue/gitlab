# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::SummarizeSubmittedReviewService, feature_category: :code_review_workflow do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:resource) { create(:merge_request, source_project: project, target_project: project, author: user) }

  let(:summarize_submitted_review_enabled) { true }
  let(:current_user) { user }
  let(:options) { {} }

  describe '#perform' do
    let(:action_name) { :summarize_submitted_review }
    let(:content) { 'Summarize submitted review' }

    before_all do
      group.add_guest(user)
    end

    before do
      allow(Ability).to receive(:allowed?).and_call_original
      allow(Ability)
        .to receive(:allowed?)
        .with(user, :summarize_submitted_review, resource)
        .and_return(summarize_submitted_review_enabled)
    end

    subject { described_class.new(current_user, resource, options).execute }

    it_behaves_like 'service not emitting message for user prompt' do
      subject { described_class.new(current_user, resource, options) }
    end

    it_behaves_like 'completion worker sync and async' do
      subject { described_class.new(current_user, resource, options) }
    end

    it_behaves_like 'llm service does not cache user request' do
      subject { described_class.new(current_user, resource, options) }
    end

    context 'when user is not member of project group' do
      let(:current_user) { create(:user) }

      it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
    end

    context 'when general feature flag is disabled' do
      before do
        stub_feature_flags(openai_experimentation: false)
      end

      it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
    end

    context 'when resource is not a merge_request' do
      let(:resource) { create(:epic, group: group) }

      it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
    end

    context 'when user has no ability to summarize_submitted_review' do
      let(:summarize_submitted_review_enabled) { false }

      it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
    end
  end
end
