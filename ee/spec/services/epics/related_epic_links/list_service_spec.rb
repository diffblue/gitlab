# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::ListService do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:group2) { create(:group, :public) }
  let_it_be(:group3) { create(:group, :private) }
  let_it_be(:source_epic) { create(:epic, group: group) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group2) }
  let_it_be(:epic3) { create(:epic, group: group2, confidential: true) } # not visible because user is guest
  let_it_be(:epic4) { create(:epic, group: group3) } # user has no access to epic's group
  let_it_be(:epic_link1) { create(:related_epic_link, source: source_epic, target: epic1) }
  let_it_be(:epic_link2) { create(:related_epic_link, source: source_epic, target: epic2) }
  let_it_be(:epic_link3) { create(:related_epic_link, source: source_epic, target: epic3) }
  let_it_be(:epic_link4) { create(:related_epic_link, source: source_epic, target: epic4) }

  before do
    stub_licensed_features(epics: true, related_epics: true)
    group2.add_guest(user)
  end

  describe '#execute' do
    subject { described_class.new(source_epic, user).execute }

    it 'returns JSON list of related epics visible to user' do
      expect(subject.size).to eq(2)

      expect(subject).to include(include(id: epic1.id,
                                         title: epic1.title,
                                         state: epic1.state,
                                         confidential: epic1.confidential,
                                         link_type: 'relates_to',
                                         reference: epic1.to_reference(source_epic.group),
                                         path: "/groups/#{epic1.group.full_path}/-/epics/#{epic1.iid}"))
      expect(subject).to include(include(id: epic2.id,
                                         title: epic2.title,
                                         state: epic2.state,
                                         confidential: epic2.confidential,
                                         link_type: 'relates_to',
                                         reference: epic2.to_reference(source_epic.group),
                                         path: "/groups/#{epic2.group.full_path}/-/epics/#{epic2.iid}"))
    end
  end
end
