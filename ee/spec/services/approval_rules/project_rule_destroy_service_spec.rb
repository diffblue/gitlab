# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApprovalRules::ProjectRuleDestroyService do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  describe '#execute' do
    let!(:project_rule) { create(:approval_project_rule, project: project) }
    let(:current_user) { create(:user, name: 'Bruce Wayne') }

    subject { described_class.new(project_rule, current_user).execute }

    shared_context 'an audit event is added' do
      it 'adds an audit event' do
        expect { subject }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details).to include({
                                                     author_name: current_user.name,
                                                     custom_message: 'Deleted approval rule',
                                                     target_type: 'ApprovalProjectRule',
                                                     target_id: project_rule.id
                                                   })
      end

      before do
        stub_licensed_features(external_audit_events: true)
        group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
      end

      it_behaves_like 'sends correct event type in audit event stream' do
        let_it_be(:event_type) { 'approval_rule_deleted' }
      end
    end

    context 'when there is no merge request rules' do
      it 'destroys project rule' do
        expect { subject }.to change { ApprovalProjectRule.count }.by(-1)
      end

      include_context 'an audit event is added'
    end

    context 'when there is a merge request rule' do
      let!(:merge_request_rule) do
        create(:approval_merge_request_rule, merge_request: merge_request).tap do |rule|
          rule.approval_project_rule = project_rule
        end
      end

      context 'when open' do
        it 'destroys merge request rules' do
          expect { subject }.to change { ApprovalMergeRequestRule.count }.by(-1)
        end

        include_context 'an audit event is added'
      end

      context 'when merged' do
        before do
          merge_request.mark_as_merged!
        end

        it 'does nothing' do
          expect { subject }.not_to change { ApprovalMergeRequestRule.count }
        end

        include_context 'an audit event is added'
      end
    end
  end
end
