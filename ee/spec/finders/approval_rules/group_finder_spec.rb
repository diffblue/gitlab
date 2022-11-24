# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::GroupFinder do
  let_it_be_with_reload(:rule) { create(:approval_project_rule) }
  let_it_be(:user) { create(:user) }

  let_it_be(:public_group) { create(:group, name: 'public_group') }
  let_it_be(:private_inaccessible_group) { create(:group, :private, name: 'private_inaccessible_group') }
  let_it_be(:private_accessible_group) { create(:group, :private, name: 'private_accessible_group') }
  let_it_be(:private_accessible_subgroup) do
    create(:group, :private, parent: private_accessible_group, name: 'private_accessible_subgroup')
  end

  subject { described_class.new(rule, user) }

  before do
    private_accessible_group.add_owner(user)
  end

  context 'when with inaccessible groups' do
    before do
      rule.groups = [public_group, private_inaccessible_group, private_accessible_group, private_accessible_subgroup]
    end

    it 'returns groups' do
      expect(subject.visible_groups).to contain_exactly(
        public_group, private_accessible_group, private_accessible_subgroup
      )
      expect(subject.hidden_groups).to contain_exactly(private_inaccessible_group)
      expect(subject.contains_hidden_groups?).to eq(true)
    end

    context 'when user is an admin', :enable_admin_mode do
      subject { described_class.new(rule, create(:admin)) }

      it 'returns groups' do
        expect(subject.visible_groups).to contain_exactly(
          public_group, private_accessible_group, private_accessible_subgroup, private_inaccessible_group
        )
        expect(subject.hidden_groups).to be_empty
        expect(subject.contains_hidden_groups?).to eq(false)
      end
    end

    context 'when user is not authorized' do
      subject { described_class.new(rule, nil) }

      it 'returns only public groups' do
        expect(subject.visible_groups).to contain_exactly(
          public_group
        )
        expect(subject.hidden_groups).to contain_exactly(
          private_accessible_group, private_accessible_subgroup, private_inaccessible_group
        )
        expect(subject.contains_hidden_groups?).to eq(true)
      end
    end

    context 'avoid N+1 query', :request_store do
      it 'avoids N+1 database queries' do
        rule.reload

        count = ActiveRecord::QueryRecorder.new { subject.visible_groups }.count

        # Clear cached association and request cache
        rule.reload
        RequestStore.clear!

        rule.groups << create(:group, :private, parent: private_accessible_group, name: 'private_accessible_subgroup2')

        expect { described_class.new(rule, user).visible_groups }.not_to exceed_query_limit(count)
      end
    end
  end

  context 'when without inaccessible groups' do
    before do
      rule.groups = [public_group, private_accessible_group, private_accessible_subgroup]
    end

    it 'returns groups' do
      expect(subject.visible_groups).to contain_exactly(
        public_group, private_accessible_group, private_accessible_subgroup
      )
      expect(subject.hidden_groups).to be_empty
      expect(subject.contains_hidden_groups?).to eq(false)
    end
  end
end
