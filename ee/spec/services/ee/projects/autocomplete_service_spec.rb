# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::AutocompleteService do
  let_it_be(:group, refind: true) { create(:group, :nested, :private, avatar: fixture_file_upload('spec/fixtures/dk.png')) }
  let_it_be(:project) { create(:project, group: group) }

  let(:user) { create(:user) }
  let!(:epic) { create(:epic, group: group, author: user) }

  subject { described_class.new(project, user) }

  before do
    group.add_developer(user)
  end

  describe '#epics' do
    let(:expected_attributes) { [:iid, :title, :group_id, :group] }

    before do
      stub_licensed_features(epics: true)
    end

    it 'returns nothing if not allowed' do
      guest = create(:user)

      epics = described_class.new(project, guest).epics

      expect(epics).to be_empty
    end

    it 'returns epics from group' do
      result = subject.epics.map { |epic| epic.slice(expected_attributes) }

      expect(result).to contain_exactly(epic.slice(expected_attributes))
    end
  end
end
