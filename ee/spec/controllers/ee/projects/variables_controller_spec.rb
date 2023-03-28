# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::VariablesController, feature_category: :secrets_management do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'PATCH #update' do
    subject(:patch_update) do
      patch :update,
        params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        variables_attributes: [variable_attributes]
      },
        format: :json
    end

    before do
      stub_licensed_features(audit_events: true)
    end

    context 'when creating variable' do
      let(:variable_attributes) do
        { key: 'new_key',
          secret_value: 'dummy_value',
          protected: 'false',
          environment_scope: '*' }
      end

      it 'logs audit event' do
        expect { patch_update }.to change { AuditEvent.count }.from(0).to(1)
      end

      it 'logs variable creation' do
        patch_update

        audit_event = AuditEvent.last.present

        expect(audit_event.action).to eq('Added ci variable')
        expect(audit_event.target).to eq('new_key')
      end
    end

    context 'when updating variable protection' do
      let(:variable) { create(:ci_variable, project: project, protected: false) }

      let(:variable_attributes) do
        { id: variable.id,
          protected: 'true' }
      end

      it 'logs audit event' do
        expect { patch_update }.to change { AuditEvent.count }.from(0).to(1)
      end

      it 'logs variable protection update' do
        patch_update

        audit_event = AuditEvent.last.present

        expect(audit_event.action).to eq('Changed variable protection from false to true')
        expect(audit_event.target).to eq(variable.key)
      end
    end

    context 'when destroying variable' do
      let(:variable) { create(:ci_variable, project: project) }

      let(:variable_attributes) do
        { key: variable.key,
          _destroy: 'true' }
      end

      it 'logs audit event' do
        expect { patch_update }.to change { AuditEvent.count }.from(0).to(1)
      end

      it 'logs variable destruction' do
        patch_update

        audit_event = AuditEvent.last.present

        expect(audit_event.action).to eq('Removed ci variable')
        expect(audit_event.target).to eq(variable.key)
      end
    end
  end
end
