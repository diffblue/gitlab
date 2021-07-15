# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SyncCodeOwnerApprovalRules do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:rb_owners) { create_list(:user, 2) }
  let_it_be(:doc_owners) { create_list(:user, 2) }
  let_it_be(:rb_group_owners) { create_list(:group, 2) }
  let_it_be(:doc_group_owners) { create_list(:group, 2) }

  let(:rb_entry) { build_entry('*.rb', rb_owners, rb_group_owners) }
  let(:doc_entry) { build_entry('doc/*', doc_owners, doc_group_owners) }
  let(:entries) { [rb_entry, doc_entry] }

  def build_entry(pattern, users, groups)
    text = (users + groups).map(&:to_reference).join(' ')
    entry = Gitlab::CodeOwners::Entry.new(pattern, text)

    entry.add_matching_users_from(users)
    entry.add_matching_groups_from(groups)

    entry
  end

  subject(:service) { described_class.new(merge_request) }

  describe '#execute' do
    before do
      allow(Gitlab::CodeOwners)
        .to receive(:entries_for_merge_request).with(merge_request, merge_request_diff: nil)
              .and_return(entries)
    end

    it "creates rules for code owner entries that don't have a rule" do
      expect { service.execute }.to change { merge_request.approval_rules.count }.by(2)

      rb_rule = merge_request.approval_rules.code_owner.find_by(name: rb_entry.pattern)
      doc_rule = merge_request.approval_rules.code_owner.find_by(name: doc_entry.pattern)

      expect(rb_rule.users).to eq(rb_owners)
      expect(doc_rule.users).to eq(doc_owners)

      expect(rb_rule.groups).to match_array(rb_group_owners)
      expect(doc_rule.groups).to match_array(doc_group_owners)
    end

    it 'deletes rules that are not relevant anymore' do
      other_rule = create(:code_owner_rule, merge_request: merge_request)

      service.execute

      expect(merge_request.approval_rules).not_to include(other_rule)
      expect { other_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'updates rules for which the users changed' do
      other_rule = create(:code_owner_rule, merge_request: merge_request, name: '*.rb')
      other_rule.users += doc_owners
      other_rule.groups += doc_group_owners
      other_rule.save!

      service.execute

      expect(other_rule.reload.users).to eq(rb_owners)
      expect(other_rule.reload.groups).to match_array(rb_group_owners)
    end

    context 'when merge request is already merged' do
      let(:merge_request) { build(:merge_request, :merged) }

      it 'logs an error' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .with(
            instance_of(described_class::AlreadyMergedError),
            hash_including(
              merge_request_id: merge_request.id,
              merge_request_iid: merge_request.iid,
              project_id: merge_request.project_id
            )
          ).and_call_original

        expect(service.execute).to eq(nil)
      end
    end
  end
end
