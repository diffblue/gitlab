# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::GenerateSummaryService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }

  describe '#perform' do
    subject { described_class.new(user, resource, {}).execute }

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

    context 'for a merge request' do
      let_it_be(:resource) { create(:merge_request, source_project: project) }

      it_behaves_like "issuable without notes"

      context 'with notes' do
        before do
          create_pair(:note_on_merge_request, project: resource.project, noteable: resource)
        end

        it_behaves_like "issuable with notes"
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
      end
    end

    context 'for an epic' do
      let_it_be(:resource) { create(:epic) }

      it_behaves_like "issuable without notes"

      context 'with notes' do
        before do
          create_pair(:note_on_epic, noteable: resource)
        end

        it_behaves_like "issuable with notes"
      end
    end
  end
end
