# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DescriptionVersion do
  describe 'associations' do
    it { is_expected.to belong_to :epic }
  end

  describe 'validations' do
    it 'is valid when epic_id is set' do
      expect(described_class.new(epic_id: 1)).to be_valid
    end
  end

  describe '#previous_version' do
    let(:issue) { create(:issue) }
    let(:previous_version) { create(:description_version, issue: issue) }
    let(:current_version) { create(:description_version, issue: issue) }

    before do
      create(:description_version, issue: issue)
      create(:description_version)

      previous_version
      current_version

      create(:description_version, issue: issue)
    end

    it 'returns the previous version for the same issuable' do
      expect(current_version.previous_version).to eq(previous_version)
    end
  end

  describe '#delete!' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:merge_request) { create(:merge_request) }
    let_it_be(:epic) { create(:epic) }

    before_all do
      2.times do
        create(:description_version, issue: issue)
        create_list(:description_version, 2, epic: epic)
        create(:description_version, merge_request: merge_request)
      end
    end

    def deleted_count
      DescriptionVersion
        .where('issue_id = ? or epic_id = ? or merge_request_id = ?', issue.id, epic.id, merge_request.id)
        .where.not(deleted_at: nil)
        .count
    end

    it 'broadcasts notes update' do
      version = epic.description_versions.last

      expect(epic).to receive(:broadcast_notes_changed)

      version.delete!
    end

    context 'when start_id is not present' do
      it 'only delayed deletes description_version' do
        version = epic.description_versions.last

        version.delete!

        expect(version.reload.deleted_at).to be_present
        expect(deleted_count).to eq(1)
      end
    end

    context 'when start_id is present' do
      it 'delayed deletes description versions of same issuable up to start_id' do
        description_version = epic.description_versions.last.previous_version
        starting_version = epic.description_versions.second

        description_version.delete!(start_id: starting_version.id)

        expect(epic.description_versions.first.deleted_at).to be_nil
        expect(epic.description_versions.second.deleted_at).to be_present
        expect(epic.description_versions.third.deleted_at).to be_present
        expect(epic.description_versions.fourth.deleted_at).to be_nil
        expect(deleted_count).to eq(2)
      end
    end
  end
end
