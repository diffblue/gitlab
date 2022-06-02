# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::GroupSubgroupsFinder do
  describe '#execute' do
    let_it_be(:group) { create(:group, :private) }
    let_it_be(:subgroup_1) { create(:group, :private, parent: group) }
    let_it_be(:subgroup_2) { create(:group, :private, parent: group) }
    let_it_be(:grandchild_1) { create(:group, :private, parent: subgroup_1) }
    let_it_be(:member_in_group) { create(:user).tap { |u| group.add_reporter(u) } }
    let_it_be(:member_in_subgroup) { create(:user).tap { |u| subgroup_1.add_reporter(u) } }

    let(:params) { { group_id: group.id } }
    let(:current_user) { member_in_group }

    subject { described_class.new(current_user, params).execute }

    it 'returns subgroups', :aggregate_failures do
      expect(subject.count).to eq(2)
      expect(subject).to contain_exactly(subgroup_1, subgroup_2)
    end

    context 'when the number of groups exceeds the limit' do
      before do
        stub_const("#{described_class}::LIMIT", 1)
      end

      it 'limits the result' do
        expect(subject.count).to eq(1)
      end
    end

    context 'when user does not have an access to the group' do
      let(:current_user) { member_in_subgroup }

      it 'raises an error' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
