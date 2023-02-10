# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CaptureSuggestedReviewersAcceptedService, feature_category: :workflow_automation do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:project) { merge_request.project }
  let_it_be(:user) { merge_request.author }

  subject(:service) { described_class.new(project: project, current_user: user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    allow(merge_request).to receive(:can_suggest_reviewers?).and_return(true)
  end

  describe '#execute' do
    subject(:result) { service.execute(merge_request, reviewer_ids) }

    context 'when the reviewer IDs param is empty' do
      let(:reviewer_ids) { [] }

      it 'returns an error response', :aggregate_failures do
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('Reviewer IDs are empty')
      end
    end

    context 'when the merge request is not eligible' do
      let(:reviewer_ids) { [1, 2] }

      before do
        allow(merge_request).to receive(:can_suggest_reviewers?).and_return(false)
      end

      it 'returns an error response', :aggregate_failures do
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('Merge request is not eligible')
      end
    end

    context 'when there is no existing predictions' do
      let(:reviewer_ids) { [1, 2] }

      it 'returns an error response', :aggregate_failures do
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('No predictions are recorded')
      end
    end

    context 'when there is a validation error' do
      let(:reviewer_ids) { [1, 2] }
      let(:predictions) { build(:predictions, merge_request: merge_request) }

      before do
        allow(predictions).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        allow(merge_request).to receive(:predictions).and_return(predictions)
      end

      it 'returns an error response', :aggregate_failures do
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq('Record invalid')
      end
    end

    context 'when successful' do
      using RSpec::Parameterized::TableSyntax

      let(:reviewer_ids) { [1, 2] }

      where(:suggested, :existing_accepted, :new_accepted, :accepted) do
        %w[bob mary donald] | %w[]           | %w[donald] | %w[donald]
        %w[bob mary donald] | %w[bob]        | %w[donald] | %w[bob donald]
        %w[bob mary donald] | %w[bob]        | %w[mickey] | %w[bob]
        %w[bob mary donald] | %w[bob donald] | %w[bob]    | %w[bob donald]
      end

      with_them do
        let(:predictions) do
          build(
            :predictions,
            merge_request: merge_request,
            suggested_reviewers: { reviewers: suggested },
            accepted_reviewers: { reviewers: existing_accepted }
          )
        end

        before do
          merge_request.predictions = predictions

          allow(project).to receive(:member_usernames_among).and_return(new_accepted)
        end

        it 'returns a success response and updates predictions', :aggregate_failures do
          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload).to eq(
            {
              project_id: project.id,
              merge_request_id: merge_request.id,
              reviewers: accepted
            }
          )

          expect(predictions.reload.accepted_reviewer_usernames).to eq(accepted)
        end
      end
    end
  end
end
