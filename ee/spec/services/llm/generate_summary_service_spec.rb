# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GenerateSummaryService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let(:current_user) { user }

  describe '#perform' do
    before do
      stub_licensed_features(summarize_notes: true)
      group.add_guest(user)
    end

    subject { described_class.new(current_user, resource, {}).execute }

    shared_examples 'issuable without notes' do
      it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
    end

    shared_examples 'issuable with notes' do
      it 'enqueues a new worker' do
        expect(Llm::CompletionWorker).to receive(:perform_async).with(
          user.id, resource.id, resource.class.name, :summarize_comments
        )

        expect(subject).to be_success
      end
    end

    shared_examples 'ensures user membership' do
      context 'without membership' do
        let(:current_user) { create(:user) }

        it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
      end
    end

    shared_examples 'ensures feature flags and license' do
      context 'without the correct license' do
        before do
          stub_licensed_features(summarize_notes: false)
        end

        it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
      end

      context 'without the feature specific flag enabled' do
        before do
          stub_feature_flags(summarize_comments: false)
        end

        it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
      end

      context 'without the general feature flag enabled' do
        before do
          stub_feature_flags(openai_experimentation: false)
        end

        it { is_expected.to be_error.and have_attributes(message: eq(described_class::INVALID_MESSAGE)) }
      end
    end

    context 'for an issue' do
      let_it_be(:resource) { create(:issue, project: project) }

      it_behaves_like "issuable without notes"

      context 'with notes' do
        before do
          create_pair(:note_on_issue, project: resource.project, noteable: resource)
        end

        it_behaves_like "issuable with notes"
        it_behaves_like "ensures feature flags and license"
        it_behaves_like "ensures user membership"
      end
    end

    context 'for an epic' do
      let_it_be(:resource) { create(:epic, group: group) }

      it_behaves_like "issuable without notes"

      context 'with notes' do
        before do
          create_pair(:note_on_epic, noteable: resource)
        end

        it_behaves_like "issuable with notes"
        it_behaves_like "ensures feature flags and license"
        it_behaves_like "ensures user membership"
      end
    end
  end
end
