# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::GroupMergeRequestApprovalSettingChangesAuditor do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  context 'when group_merge_request_approval_setting is created' do
    let(:params) do
      { allow_author_approval: false,
        allow_committer_approval: false,
        allow_overrides_to_approver_list_per_merge_request: false,
        retain_approvals_on_push: false,
        require_password_to_approve: true }
    end

    let(:approval_setting) { create(:group_merge_request_approval_setting, group: group, **params) }

    subject { described_class.new(user, approval_setting, params) }

    it 'creates audit events' do
      expect { subject.execute }.to change { AuditEvent.count }.by(5)
      expect(AuditEvent.last(5).map { |e| e.details[:custom_message] })
        .to match_array ["Changed prevent merge request approval from committers from false to true",
                         "Changed prevent users from modifying MR approval rules in merge requests "\
                           "from false to true",
                         "Changed prevent merge request approval from authors from false to true",
                         "Changed require new approvals when new commits are added to an MR from false to true",
                         "Changed require user password for approvals from false to true"]
    end
  end

  context 'when group_merge_request_approval_setting is updated' do
    let_it_be(:approval_setting) do
      create(:group_merge_request_approval_setting,
             group: group,
             allow_author_approval: false,
             allow_committer_approval: false,
             allow_overrides_to_approver_list_per_merge_request: false,
             retain_approvals_on_push: false,
             require_password_to_approve: false)
    end

    let_it_be(:subject) { described_class.new(user, approval_setting, {}) }

    ::GroupMergeRequestApprovalSetting::AUDIT_LOG_ALLOWLIST.each do |column, desc|
      it 'creates an audit event' do
        approval_setting.update_attribute(column, true)

        expect { subject.execute }.to change { AuditEvent.count }.by(1)

        if column == :require_password_to_approve
          expect(AuditEvent.last.details).to include({ change: desc, from: false, to: true })
        else
          expect(AuditEvent.last.details).to include({ change: desc, from: true, to: false })
        end
      end

      it 'passes correct event type to auditor' do
        expect(::Gitlab::Audit::Auditor)
          .to receive(:audit).with(hash_including({ name: "#{column}_updated" })).and_call_original

        subject.execute
      end
    end
  end
end
