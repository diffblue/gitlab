# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Variables do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    project.add_maintainer(user)

    stub_licensed_features(audit_events: true)
  end

  describe 'POST /projects/:id/variables' do
    subject(:post_create) do
      post api("/projects/#{project.id}/variables", user), params: { key: 'new_variable', value: 'secret_value', protected: true }
    end

    it 'logs audit event' do
      expect { post_create }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable creation' do
      post_create

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq('Added ci variable')
      expect(audit_event.target).to eq('new_variable')
    end
  end

  describe 'PUT /projects/:id/variables/:key' do
    let(:variable) { create(:ci_variable, project: project, protected: false) }

    subject(:put_update) do
      put api("/projects/#{project.id}/variables/#{variable.key}", user), params: { protected: true }
    end

    it 'logs audit event' do
      expect { put_update }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable protection update' do
      put_update

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq('Changed variable protection from false to true')
      expect(audit_event.target).to eq(variable.key)
    end
  end

  describe 'DELETE /projects/:id/variables/:key' do
    let(:variable) { create(:ci_variable, project: project, protected: false) }

    subject(:delete_destroy) do
      delete api("/projects/#{project.id}/variables/#{variable.key}", user)
    end

    it 'logs audit event' do
      expect { delete_destroy }.to change(AuditEvent, :count).from(0).to(1)
    end

    it 'logs variable destruction' do
      delete_destroy

      audit_event = AuditEvent.last.present

      expect(audit_event.action).to eq('Removed ci variable')
      expect(audit_event.target).to eq(variable.key)
    end
  end
end
