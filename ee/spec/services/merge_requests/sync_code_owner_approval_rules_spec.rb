# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SyncCodeOwnerApprovalRules, feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:rb_owners) { create_list(:user, 2) }
  let_it_be(:doc_owners) { create_list(:user, 2) }
  let_it_be(:rb_group_owners) { create_list(:group, 2) }
  let_it_be(:doc_group_owners) { create_list(:group, 2) }
  let_it_be(:rb_approvals_required) { 2 }
  let_it_be(:doc_approvals_required) { 3 }

  let(:rb_entry) { build_entry('*.rb', rb_owners, rb_group_owners, 'codeowners', rb_approvals_required) }
  let(:doc_entry) { build_entry('doc/*', doc_owners, doc_group_owners, 'codeowners', doc_approvals_required) }
  let(:entries) { [rb_entry, doc_entry] }

  def build_entry(pattern, users, groups, section = Gitlab::CodeOwners::Section::DEFAULT, approvals_required = 0)
    text = (users + groups).map(&:to_reference).join(' ')
    entry = Gitlab::CodeOwners::Entry.new(pattern, text, section, false, approvals_required)

    entry.add_matching_users_from(users)
    entry.add_matching_groups_from(groups)

    entry
  end

  def verify_correct_code_owners
    [
      [rb_entry, rb_owners, rb_group_owners, rb_approvals_required],
      [doc_entry, doc_owners, doc_group_owners, doc_approvals_required]
    ].each do |entry, users, groups|
      rule = merge_request.approval_rules.code_owner.find_by(name: entry.pattern, section: entry.section)

      expect(rule.users).to match_array(users)
      expect(rule.groups).to match_array(groups)
    end
  end

  subject(:service) { described_class.new(merge_request) }

  describe '#execute' do
    before do
      allow(Gitlab::CodeOwners)
        .to receive(:entries_for_merge_request).with(merge_request, merge_request_diff: nil)
              .and_return(entries)
    end

    it 'creates rules for code owner entries that do not have a rule' do
      expect { service.execute }.to change { merge_request.approval_rules.count }.by(2)

      verify_correct_code_owners
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
      other_rule.approvals_required += doc_approvals_required
      other_rule.save!

      service.execute

      expect(other_rule.reload.users).to match_array(rb_owners)
      expect(other_rule.reload.groups).to match_array(rb_group_owners)
      expect(other_rule.reload.approvals_required).to eq(rb_approvals_required)
    end

    context 'when multiple rules for the same pattern with different sections are specified' do
      let(:rb_entry) { build_entry('doc/', rb_owners, rb_group_owners, 'Rb owners') }
      let(:doc_entry) { build_entry('doc/', doc_owners, doc_group_owners, 'Doc owners') }

      it 'creates and updates the rules that are mapped to the entries' do
        expect { service.execute }.to change { merge_request.approval_rules.count }.by(2)

        verify_correct_code_owners

        service.execute

        verify_correct_code_owners
      end
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
