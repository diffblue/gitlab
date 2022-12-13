# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::GroupPushRulesChangesAuditor do
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  let(:push_rule) { group.build_push_rule }

  before do
    group.add_owner(current_user)
    stub_licensed_features(audit_events: true, external_audit_events: true)
    group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
  end

  subject { described_class.new(current_user, push_rule) }

  context 'when auditing group-level changes in push rules' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength
    where(:key, :old_value, :new_value, :event_name) do
      :commit_committer_check        | false      | true                | 'audit_operation'
      :commit_committer_check        | true       | false               | 'audit_operation'
      :reject_unsigned_commits       | false      | true                | 'audit_operation'
      :reject_unsigned_commits       | true       | false               | 'audit_operation'
      :deny_delete_tag               | false      | true                | 'audit_operation'
      :deny_delete_tag               | true       | false               | 'audit_operation'
      :member_check                  | false      | true                | 'audit_operation'
      :member_check                  | true       | false               | 'audit_operation'
      :prevent_secrets               | false      | true                | 'audit_operation'
      :prevent_secrets               | true       | false               | 'audit_operation'
      :branch_name_regex             | nil        | "\\Asecurity-.*\\z" | 'group_push_rules_branch_name_regex_updated'
      :branch_name_regex             | ".*\\w{2}" | "\\Asecurity-.*\\z" | 'group_push_rules_branch_name_regex_updated'
      :commit_message_regex          | nil        | "\\Asecurity-.*\\z" | 'group_push_rules_commit_message_regex_updated'
      :commit_message_regex          | ".*\\w{2}" | "\\Asecurity-.*\\z" | 'group_push_rules_commit_message_regex_updated'
      :commit_message_negative_regex | nil        | "\\Asecurity-.*\\z" | 'group_push_rules_commit_message_negative_regex_updated'
      :commit_message_negative_regex | ".*\\w{2}" | "\\Asecurity-.*\\z" | 'group_push_rules_commit_message_negative_regex_updated'
      :author_email_regex            | nil        | "\\Asecurity-.*\\z" | 'group_push_rules_author_email_regex_updated'
      :author_email_regex            | ".*\\w{2}" | "\\Asecurity-.*\\z" | 'group_push_rules_author_email_regex_updated'
      :file_name_regex               | nil        | "\\Asecurity-.*\\z" | 'group_push_rules_file_name_regex_updated'
      :file_name_regex               | ".*\\w{2}" | "\\Asecurity-.*\\z" | 'group_push_rules_file_name_regex_updated'
      :max_file_size                 | 0          | 132                 | 'group_push_rules_max_file_size_updated'
      :max_file_size                 | 12         | 42                  | 'group_push_rules_max_file_size_updated'
    end
    # rubocop:enable Layout/LineLength

    with_them do
      before do
        push_rule.update!(key => old_value)
        push_rule.update!(key => new_value)
      end

      it 'audits the change in push rule correctly', :aggregate_failures do
        expect do
          subject.execute
        end.to change { AuditEvent.count }.by(1)

        event = AuditEvent.last

        expect(event.author).to eq(current_user)
        expect(event.details[:change]).to eq(::PushRule::AUDIT_LOG_ALLOWLIST[key])
        expect(event.details[:from]).to eq(old_value)
        expect(event.details[:to]).to eq(new_value)
        expect(event.entity).to eq(group)
      end

      it 'streams correct audit event', :aggregate_failures do
        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
          .with(event_name, anything, anything)
        subject.execute
      end
    end
  end
end
