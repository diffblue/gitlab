# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::PushRules::ProjectPushRulesChangesAuditor, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:current_user) { create(:user) }

  let(:push_rule) { project.build_push_rule }

  before do
    stub_licensed_features(audit_events: true, external_audit_events: true)
    group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
  end

  subject { described_class.new(current_user, push_rule) }

  context 'when auditing project-level changes in push rules' do
    using RSpec::Parameterized::TableSyntax

    # rubocop:disable Layout/LineLength
    where(:key, :old_value, :new_value, :event_name) do
      :commit_committer_check        | false      | true                | 'project_push_rules_commit_committer_check_updated'
      :commit_committer_check        | true       | false               | 'project_push_rules_commit_committer_check_updated'
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
        expect(event.entity).to eq(project)
      end

      it 'streams correct audit event', :aggregate_failures do
        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
                                                            .with(event_name, anything, anything)
        subject.execute
      end
    end
  end
end
