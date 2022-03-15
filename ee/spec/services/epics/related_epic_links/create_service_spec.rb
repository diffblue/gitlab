# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::RelatedEpicLinks::CreateService do
  describe '#execute' do
    let_it_be(:user) { create :user }
    let_it_be(:group) { create :group }
    let_it_be(:issuable) { create :epic, group: group }
    let_it_be(:issuable2) { create :epic, group: group }
    let_it_be(:guest_issuable) { create :epic }
    let_it_be(:another_group) { create :group }
    let_it_be(:issuable3) { create :epic, group: another_group }
    let_it_be(:issuable_a) { create :epic, group: group }
    let_it_be(:issuable_b) { create :epic, group: group }
    let_it_be(:issuable_link) { create :related_epic_link, source: issuable, target: issuable_b, link_type: IssuableLink::TYPE_RELATES_TO }

    let(:issuable_parent) { issuable.group }
    let(:issuable_type) { :epic }
    let(:issuable_link_class) { Epic::RelatedEpicLink }
    let(:params) { {} }

    before do
      stub_licensed_features(epics: true, related_epics: true)
      group.add_developer(user)
      guest_issuable.group.add_guest(user)
      another_group.add_developer(user)
    end

    it_behaves_like 'issuable link creation'
    it_behaves_like 'issuable link creation with blocking link_type' do
      let(:params) do
        { issuable_references: [issuable2.to_reference, issuable3.to_reference(issuable3.group, full: true)] }
      end
    end

    context 'when related_epics is not available for target epic' do
      let(:params) do
        { issuable_references: [issuable3.to_reference(issuable3.group, full: true)] }
      end

      subject { described_class.new(issuable, user, params).execute }

      before do
        stub_licensed_features(epics: true, related_epics: false)
        allow(issuable.group).to receive(:licensed_feature_available?).with(:related_epics).and_return(true)
      end

      it 'creates relationships' do
        expect { subject }.to change(issuable_link_class, :count).by(1)

        expect(issuable_link_class.find_by!(target: issuable3)).to have_attributes(source: issuable, link_type: 'relates_to')
      end
    end
  end
end
