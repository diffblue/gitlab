# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Llm::Serializers::IssueSerializer, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue) }
  let_it_be(:content_limit) { 1000 }
  let(:serializer_double) { instance_double(::IssueSerializer) }

  describe '.serialize' do
    it 'serializes the issue and its comments' do
      serialized_issue = described_class.serialize(issue: issue, user: user, content_limit: content_limit)

      expect(serialized_issue).to include(:issue_comments)
      expect(serialized_issue[:issue_comments]).to be_an(Array)
    end

    it 'calls serializer to serializes the issue' do
      expect(serializer_double).to receive(:represent).with(issue).and_return({ id: 1 })
      expect(::IssueSerializer).to receive(:new).with(current_user: user, project: issue.project)
                                                .and_return(serializer_double)

      expect(described_class.serialize(issue: issue, user: user, content_limit: content_limit)).to include(
        id: 1,
        issue_comments: []
      )
    end

    context 'when there are no notes for the issue' do
      it 'returns an empty array' do
        notes = described_class.serialize(issue: issue, user: user, content_limit: content_limit).fetch(:issue_comments)

        expect(notes).to be_an(Array)
        expect(notes).to be_empty
      end
    end

    context 'when there are notes for the issue' do
      let_it_be(:note) { create(:note, noteable: issue, project: issue.project) }

      it 'returns an array with notes' do
        notes = described_class.serialize(issue: issue, user: user, content_limit: content_limit).fetch(:issue_comments)

        expect(notes).to contain_exactly(note.note)
      end

      context 'when there more notes for the issue' do
        it 'returns an array with notes no longer than limit',
          quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/421850' do
          create(:note, noteable: issue, project: issue.project, note: '*' * content_limit)

          notes = described_class.serialize(issue: issue, user: user, content_limit: content_limit)
                                 .fetch(:issue_comments)

          expect(notes).to be_an(Array)
          expect(notes).to contain_exactly(note.note)
        end
      end
    end
  end
end
