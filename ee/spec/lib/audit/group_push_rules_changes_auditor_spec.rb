# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::GroupPushRulesChangesAuditor do
  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }

  let(:push_rule) { group.build_push_rule }

  before do
    group.add_owner(current_user)
  end

  subject { described_class.new(current_user, push_rule) }

  context 'auditing group-level changes' do
    using RSpec::Parameterized::TableSyntax

    where(:key, :old_value, :new_value) do
      :commit_committer_check        | false      | true
      :commit_committer_check        | true       | false
      :reject_unsigned_commits       | false      | true
      :reject_unsigned_commits       | true       | false
      :deny_delete_tag               | false      | true
      :deny_delete_tag               | true       | false
      :member_check                  | false      | true
      :member_check                  | true       | false
      :prevent_secrets               | false      | true
      :prevent_secrets               | true       | false
      :branch_name_regex             | nil        | "\\Asecurity-.*\\z"
      :branch_name_regex             | ".*\\w{2}" | "\\Asecurity-.*\\z"
      :commit_message_regex          | nil        | "\\Asecurity-.*\\z"
      :commit_message_regex          | ".*\\w{2}" | "\\Asecurity-.*\\z"
      :commit_message_negative_regex | nil        | "\\Asecurity-.*\\z"
      :commit_message_negative_regex | ".*\\w{2}" | "\\Asecurity-.*\\z"
      :author_email_regex            | nil        | "\\Asecurity-.*\\z"
      :author_email_regex            | ".*\\w{2}" | "\\Asecurity-.*\\z"
      :file_name_regex               | nil        | "\\Asecurity-.*\\z"
      :file_name_regex               | ".*\\w{2}" | "\\Asecurity-.*\\z"
      :max_file_size                 | 0          | 132
      :max_file_size                 | 12         | 42
    end

    with_them do
      it 'audits the change in push rule correctly', :aggregate_failures do
        push_rule.update!(key => old_value)
        expect do
          push_rule.update!(key => new_value)
          subject.execute
        end.to change { AuditEvent.count }.by(1)

        event = AuditEvent.last
        expect(event.author).to eq(current_user)
        expect(event.details[:change]).to eq(::PushRule::AUDIT_LOG_ALLOWLIST[key])
        expect(event.details[:from]).to eq(old_value)
        expect(event.details[:to]).to eq(new_value)
        expect(event.entity).to eq(group)
      end
    end
  end

  context 'auditing group-level events to external stream' do     
    before do
      stub_licensed_features(audit_events: true, external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')  
    end

    it 'streams correct audit event for max_file_size', :aggregate_failures do
      push_rule.update!('max_file_size' => 50)
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_max_file_size_updated', anything, anything)  
      subject.execute
    end  

    it 'streams correct audit event for file_name_regex', :aggregate_failures do
      push_rule.update!('file_name_regex' => '.*\\w{2}')
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_file_name_regex_updated', anything, anything)  
      subject.execute
    end 

    it 'streams correct audit event for author_email_regex', :aggregate_failures do
      push_rule.update!('author_email_regex' => '.*\\w{2}')
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_author_email_regex_updated', anything, anything)  
      subject.execute
    end 

    it 'streams correct audit event for commit_message_negative_regex', :aggregate_failures do
      push_rule.update!('commit_message_negative_regex' => '.*\\w{2}')
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_commit_message_negative_regex_updated', anything, anything)  
      subject.execute
    end 

    it 'streams correct audit event for commit_message_regex', :aggregate_failures do
      push_rule.update!('commit_message_regex' => '.*\\w{2}')
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_commit_message_regex_updated', anything, anything)  
      subject.execute
    end 

    it 'streams correct audit event for branch_name_regex', :aggregate_failures do
      push_rule.update!('branch_name_regex' => '.*\\w{2}')
      expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
        .with('group_push_rules_branch_name_regex_updated', anything, anything)  
      subject.execute
    end
  end
end
