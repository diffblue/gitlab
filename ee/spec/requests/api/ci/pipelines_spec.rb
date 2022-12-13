# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Pipelines, feature_category: :continuous_integration do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :repository, creator: user) }

  let!(:pipeline) do
    create(:ci_empty_pipeline, project: project, sha: project.commit.id,
                               ref: project.default_branch, user: user)
  end

  before do
    project.add_maintainer(user)
  end

  describe 'DELETE /projects/:id/pipelines/:pipeline_id' do
    context 'authorized user' do
      let(:owner) { project.first_owner }

      context 'when audit events is enabled' do
        before do
          stub_licensed_features(extended_audit_events: true, admin_audit_log: true)
        end

        it 'does not log an audit event' do
          expect { delete api("/projects/#{project.id}/pipelines/#{pipeline.id}", owner) }.not_to change { AuditEvent.count }
        end
      end
    end
  end
end
