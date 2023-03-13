# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::CodeOwners::Entry, feature_category: :source_code_management do
  subject(:entry) do
    described_class.new(
      "/**/file",
      "@user jane@gitlab.org @group @group/nested-group",
      "Documentation"
    )
  end

  let(:user) { build(:user, username: 'user') }
  let(:group_user) { create(:user) }
  let(:group) do
    group = create(:group, path: 'Group')
    group.add_developer(group_user)
    group
  end

  it 'is uniq by the pattern and owner line' do
    equal_entry = entry.clone
    other_entry = described_class.new('/**/other_file', '@user jane@gitlab.org @group')

    expect(equal_entry).to eq(entry)
    expect([entry, equal_entry, other_entry].uniq).to contain_exactly(entry, other_entry)
  end

  describe '#users' do
    it 'raises an error if no users have been added' do
      expect { entry.users }.to raise_error(/not loaded/)
    end

    it 'returns the users in an array' do
      entry.add_matching_users_from([user])

      expect(entry.users).to eq([user])
    end
  end

  describe '#all_users' do
    it 'raises an error if users have not been loaded for groups' do
      entry.add_matching_groups_from([group])

      expect { entry.all_users }.to raise_error(/not loaded/)
    end

    it 'returns users and users from groups' do
      user.save!
      group.add_reporter(user)

      entry.add_matching_groups_from(Group.with_users)
      entry.add_matching_users_from([user])

      expect(entry.all_users).to contain_exactly(user, group_user)
    end
  end

  describe '#groups' do
    it 'raises an error if no groups have been added' do
      expect { entry.groups }.to raise_error(/not loaded/)
    end

    it 'returns mentioned groups' do
      entry.add_matching_groups_from([group])

      expect(entry.groups).to eq([group])
    end
  end

  describe '#add_matching_groups_from' do
    it 'returns only mentioned groups, case-insensitively' do
      group2 = create(:group, path: 'Group2')
      nested_group = create(:group, path: 'nested-group', parent: group)

      entry.add_matching_groups_from([group, group2, nested_group])

      expect(entry.groups).to eq([group, nested_group])
    end
  end

  describe '#add_matching_users_from' do
    it 'does not add the same user twice' do
      2.times { entry.add_matching_users_from([user]) }

      expect(entry.users).to contain_exactly(user)
    end

    it 'raises an error when adding a user without emails preloaded' do
      expect { entry.add_matching_users_from([build(:user)]) }.to raise_error(/Emails not loaded/)
    end

    it 'only adds users mentioned in the owner line' do
      other_user = create(:user)
      other_user.emails.load

      entry.add_matching_users_from([other_user, user])

      expect(entry.users).to contain_exactly(user)
    end

    it 'adds users by username, case-insensitively' do
      user = build(:user, username: 'USER')

      entry.add_matching_users_from([user])

      expect(entry.users).to contain_exactly(user)
    end

    it 'adds users by primary email, case-insensitively' do
      second_user = create(:user, email: 'JANE@GITLAB.ORG')
      second_user.emails.load

      entry.add_matching_users_from([second_user, user])

      expect(entry.users).to contain_exactly(user, second_user)
    end

    context 'adding users by secondary email, case-insensitively' do
      it 'finds both users when the email address is confirmed/verified' do
        second_user = create(:user)
        second_user.emails.create!(email: 'JaNe@GitLab.org', confirmed_at: Time.current)
        second_user.emails.load

        entry.add_matching_users_from([second_user, user])

        expect(entry.users).to contain_exactly(user, second_user)
      end

      it 'finds only the first user when the email address for the second is unconfirmed/unverified' do
        second_user = create(:user)
        second_user.emails.create!(email: 'JaNe@GitLab.org')
        second_user.emails.load

        entry.add_matching_users_from([second_user, user])

        expect(entry.users).to contain_exactly(user)
      end
    end
  end

  describe "approvals_required" do
    context 'when there has approvals_required params' do
      let(:entry) do
        described_class.new(
          "/**/file",
          "@user jane@gitlab.org @group @group/nested-group",
          "Documentation",
          false,
          2)
      end

      it 'returns 2' do
        expect(entry.approvals_required).to eq(2)
      end
    end

    context 'when there has no approvals_required params' do
      let(:entry) do
        described_class.new(
          "/**/file",
          "@user jane@gitlab.org @group @group/nested-group",
          "Documentation")
      end

      it 'returns 0' do
        expect(entry.approvals_required).to eq(0)
      end
    end
  end
end
