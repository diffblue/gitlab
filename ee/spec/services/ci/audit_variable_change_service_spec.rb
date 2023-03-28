# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::AuditVariableChangeService, feature_category: :secrets_management do
  subject(:execute) { service.execute }

  let_it_be(:user) { create(:user) }

  let(:group) { create(:group) }
  let(:group_variable) { create(:ci_group_variable, group: group) }
  let(:destination) { create(:external_audit_event_destination, group: group) }
  let(:project) { create(:project, group: group) }
  let(:project_variable) { create(:ci_variable, project: project) }

  let(:service) do
    described_class.new(
      container: group, current_user: user,
      params: { action: action, variable: variable }
    )
  end

  shared_examples 'audit creation' do
    let(:action) { :create }

    it 'logs audit event' do
      expect { execute }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable group creation' do
      execute

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq(message)
      expect(audit_event.target).to eq(variable.key)
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { event_type }
    end
  end

  shared_examples 'audit when updating variable protection' do
    let(:action) { :update }

    before do
      variable.update!(protected: true)
    end

    it 'logs audit event' do
      expect { execute }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable protection update' do
      execute

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq('Changed variable protection from false to true')
      expect(audit_event.target).to eq(variable.key)
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { event_type }
    end
  end

  shared_examples 'no audit events are created' do
    context 'when creating variable' do
      let(:action) { :create }

      it 'does not log an audit event' do
        expect { execute }.not_to change(AuditEvent, :count).from(0)
      end
    end

    context 'when updating variable protection' do
      let(:action) { :update }

      before do
        variable.update!(protected: true)
      end

      it 'does not log an audit event' do
        expect { execute }.not_to change(AuditEvent, :count).from(0)
      end
    end

    context 'when destroying variable' do
      let(:action) { :destroy }

      it 'does not log an audit event' do
        expect { execute }.not_to change(AuditEvent, :count).from(0)
      end
    end
  end

  shared_examples 'when destroying variable' do
    let(:action) { :destroy }

    it 'logs audit event' do
      expect { execute }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable destruction' do
      execute

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq(message)
      expect(audit_event.target).to eq(variable.key)
    end

    it_behaves_like 'sends correct event type in audit event stream' do
      let_it_be(:event_type) { "ci_group_variable_deleted" }
    end
  end

  context 'when audits are available' do
    before do
      stub_licensed_features(audit_events: true)
      stub_licensed_features(external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    context 'when creating group variable' do
      it_behaves_like 'audit creation' do
        let(:variable) { group_variable }

        let_it_be(:message) { 'Added ci group variable' }
        let_it_be(:event_type) { "ci_group_variable_created" }
      end
    end

    context 'when updating group variable protection' do
      it_behaves_like 'audit when updating variable protection' do
        let(:variable) { group_variable }

        let_it_be(:event_type) { "ci_group_variable_updated" }
      end
    end

    context 'when deleting group variable' do
      it_behaves_like 'audit when updating variable protection' do
        let(:variable) { group_variable }

        let_it_be(:message) { 'Removed ci group variable' }
        let_it_be(:event_type) { "ci_group_variable_updated" }
      end
    end

    context 'when creating project variable' do
      it_behaves_like 'audit creation' do
        let(:variable) { project_variable }

        let_it_be(:message) { 'Added ci variable' }
        let_it_be(:event_type) { "ci_variable_created" }
      end
    end

    context 'when updating project variable protection' do
      it_behaves_like 'audit when updating variable protection' do
        let(:variable) { project_variable }

        let_it_be(:event_type) { "ci_variable_updated" }
      end
    end

    context 'when deleting project variable' do
      it_behaves_like 'audit when updating variable protection' do
        let(:variable) { project_variable }

        let_it_be(:message) { 'Removed ci variable' }
        let_it_be(:event_type) { "ci_variable_updated" }
      end
    end
  end

  context 'when audits are not available' do
    before do
      stub_licensed_features(audit_events: false)
    end

    context 'for group variable' do
      it_behaves_like 'no audit events are created' do
        let(:variable) { group_variable }
      end
    end

    context 'for project variable' do
      it_behaves_like 'no audit events are created' do
        let(:variable) { project_variable }
      end
    end
  end
end
