# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicPresenter do
  include UsersHelper
  include Gitlab::Routing.url_helpers

  let(:user) { create(:user) }
  let(:group) { create(:group, path: "pukeko_parent_group") }
  let(:parent_epic) { create(:epic, group: group, start_date: Date.new(2000, 1, 10), due_date: Date.new(2000, 1, 20), iid: 10) }
  let(:epic) { create(:epic, group: group, author: user, parent: parent_epic) }

  subject(:presenter) { described_class.new(epic, current_user: user) }

  describe '#show_data' do
    let(:milestone1) { create(:milestone, title: 'make me a sandwich', start_date: '2010-01-01', due_date: '2019-12-31') }
    let(:milestone2) { create(:milestone, title: 'make me a pizza', start_date: '2020-01-01', due_date: '2029-12-31') }

    before do
      epic.update!(
        start_date_sourcing_milestone: milestone1, start_date: Date.new(2000, 1, 1),
        due_date_sourcing_milestone: milestone2, due_date: Date.new(2000, 1, 2)
      )
      stub_licensed_features(epics: true)
    end

    it 'has correct keys' do
      expect(presenter.show_data.keys).to match_array([:initial, :meta])
    end

    it 'has correct ancestors' do
      metadata     = Gitlab::Json.parse(presenter.show_data[:meta])
      ancestor_url = metadata['ancestors'].first['url']

      expect(ancestor_url).to eq "/groups/#{parent_epic.group.full_path}/-/epics/#{parent_epic.iid}"
    end

    it 'returns the correct json schema for epic initial data' do
      data = presenter.show_data(author_icon: 'icon_path')

      expect(data[:initial]).to match_schema('epic_initial_data', dir: 'ee')
    end

    it 'returns the correct json schema for epic meta data' do
      data = presenter.show_data(author_icon: 'icon_path')

      expect(data[:meta]).to match_schema('epic_meta_data', dir: 'ee')
    end

    it 'avoids N+1 database queries' do
      group1 = create(:group)
      group2 = create(:group, parent: group1)
      epic1 = create(:epic, group: group1)
      epic2 = create(:epic, group: group1, parent: epic1)
      create(:epic, group: group2, parent: epic2)

      control_count = ActiveRecord::QueryRecorder.new { presenter.show_data }

      expect { presenter.show_data }.not_to exceed_query_limit(control_count)
    end

    it 'does not include subscribed in initial data' do
      expect(Gitlab::Json.parse(presenter.show_data[:initial])).not_to include('subscribed')
    end
  end

  describe '#group_epic_path' do
    it 'returns correct path' do
      expect(presenter.group_epic_path).to eq group_epic_path(epic.group, epic)
    end
  end

  describe '#group_epic_link_path' do
    it 'returns correct path' do
      expect(presenter.group_epic_link_path).to eq group_epic_link_path(epic.group, epic.parent.iid, epic.id)
    end

    context 'when in subgroups' do
      let!(:subgroup) { create(:group, parent: group, path: "hedgehogs_subgroup") }
      let(:child_epic) { create(:epic, group: subgroup, iid: 1, parent: epic) }

      subject(:presenter) { described_class.new(child_epic, current_user: user) }

      it 'returns the correct path' do
        expected_result = "/groups/#{group.path}/-/epics/#{epic.iid}/links/#{child_epic.id}"

        expect(presenter.group_epic_link_path).to eq expected_result
      end
    end

    it 'returns nothing with nil parent' do
      epic.parent = nil

      expect(presenter.group_epic_link_path).to be_nil
    end
  end

  describe '#epic_reference' do
    it 'returns a reference' do
      expect(presenter.epic_reference).to eq "&#{epic.iid}"
    end

    it 'returns a full reference' do
      expect(presenter.epic_reference(full: true)).to eq "#{epic.parent.group.path}&#{epic.iid}"
    end
  end
end
