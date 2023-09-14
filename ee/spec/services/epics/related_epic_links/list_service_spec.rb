# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::ListService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:source_group) { create(:group, :public) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:private_group) { create(:group, :private) }

  let_it_be(:source_epic) { create(:epic, group: source_group) }
  let_it_be(:public_epic) { create(:epic, group: public_group) }
  let_it_be(:confidential_epic) { create(:epic, group: public_group, confidential: true) }
  let_it_be(:private_epic) { create(:epic, group: private_group) }

  let_it_be(:epic_link1) { create(:related_epic_link, source: source_epic, target: public_epic) }
  let_it_be(:epic_link2) { create(:related_epic_link, source: source_epic, target: confidential_epic) }
  let_it_be(:epic_link3) { create(:related_epic_link, source: source_epic, target: private_epic) }

  let_it_be(:relation_path1) { path_for(epic_link1) }
  let_it_be(:relation_path2) { path_for(epic_link2) }
  let_it_be(:relation_path3) { path_for(epic_link3) }

  describe '#execute' do
    subject { described_class.new(source_epic, user).execute }

    context 'when user is only member of source group' do
      before do
        source_group.add_guest(user)
        stub_licensed_features(epics: true, related_epics: true)
      end

      it 'returns JSON list of related epics visible to user excluding relation_path' do
        expect(subject).to include(include(epic_response(public_epic, relation_path1)))
      end

      context 'when epic_relations_for_non_members is disabled' do
        before do
          stub_feature_flags(epic_relations_for_non_members: false)
        end

        it 'returns JSON list of related epics visible to user excluding relation_path' do
          expect(subject).to include(include(epic_response(public_epic)))
        end
      end

      context 'when user is a guest in public group' do
        before do
          public_group.add_guest(user)
        end

        it 'returns JSON list of related epics visible to user including relation_path' do
          expect(subject).to include(include(epic_response(public_epic, relation_path1)))
        end
      end

      context 'when user is a reporter in public group' do
        before do
          public_group.add_reporter(user)
        end

        it 'returns JSON list of related epics visible to user including relation_path' do
          expect(subject).to include(include(epic_response(public_epic, relation_path1)))
          expect(subject).to include(include(epic_response(confidential_epic, relation_path2)))
        end
      end

      context 'when user is a guest in private group' do
        before do
          public_group.add_reporter(user)
          private_group.add_guest(user)
        end

        it 'returns JSON list of related epics visible to user including relation_path' do
          expect(subject).to include(include(epic_response(public_epic, relation_path1)))
          expect(subject).to include(include(epic_response(confidential_epic, relation_path2)))
          expect(subject).to include(include(epic_response(private_epic, relation_path3)))
        end
      end
    end
  end

  def epic_response(epic, relation_path = nil)
    {
      id: epic.id,
      title: epic.title,
      state: epic.state,
      confidential: epic.confidential,
      link_type: 'relates_to',
      relation_path: relation_path,
      reference: epic.to_reference(source_epic.group),
      path: "/groups/#{epic.group.full_path}/-/epics/#{epic.iid}"
    }
  end

  def path_for(link)
    "/groups/#{source_group.full_path}/-/epics/#{source_epic.iid}/related_epic_links/#{link.id}"
  end
end
