# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ProtectedBranchAuditEventService, :request_store do
  let(:merge_level) { 'Maintainers' }
  let(:push_level) { 'No one' }
  let_it_be(:author) { create(:user, :with_sign_ins) }
  let_it_be(:group) { create(:group) }
  let_it_be(:destination) { create(:external_audit_event_destination, group: group) }
  let_it_be(:entity) { create(:project, creator: author, group: group) }
  let_it_be(:protected_branch) { create(:protected_branch, :no_one_can_push, allow_force_push: true, code_owner_approval_required: true, project: entity) }

  let(:logger) { instance_spy(Gitlab::AuditJsonLogger) }
  let(:ip_address) { '192.168.15.18' }

  describe '#security_event' do
    shared_examples 'loggable' do |action, event_type|
      context "when a protected_branch is #{action}" do
        let(:service) { described_class.new(author, protected_branch, action) }

        before do
          stub_licensed_features(admin_audit_log: true, external_audit_events: true, code_owner_approval_required: true)
          allow(Gitlab::RequestContext.instance).to receive(:client_ip).and_return(ip_address)
        end

        it 'creates an event', :aggregate_failures do
          expect { service.execute }.to change(AuditEvent, :count).by(1)

          security_event = AuditEvent.last

          expect(security_event.details).to include(
            author_name: author.name,
            target_id: protected_branch.id,
            entity_path: entity.full_path,
            target_type: 'ProtectedBranch',
            target_details: protected_branch.name,
            allow_force_push: true,
            code_owner_approval_required: true,
            push_access_levels: [push_level],
            merge_access_levels: [merge_level],
            ip_address: ip_address
          )

          expect(security_event.author_id).to eq(author.id)
          expect(security_event.entity_id).to eq(entity.id)
          expect(security_event.entity_type).to eq('Project')
          expect(security_event.ip_address).to eq(ip_address)
        end

        it 'logs to a file with the provided details' do
          expect(::Gitlab::AuditJsonLogger).to receive(:build).and_return(logger)

          service.execute

          expect(logger).to have_received(:info).with(hash_including(
                                                        'author_id' => author.id,
                                                        'author_name' => author.name,
                                                        'entity_id' => entity.id,
                                                        'entity_type' => 'Project',
                                                        'entity_path' => entity.full_path,
                                                        'allow_force_push' => true,
                                                        'code_owner_approval_required' => true,
                                                        'merge_access_levels' => [merge_level],
                                                        'push_access_levels' => [push_level],
                                                        'target_details' => protected_branch.name,
                                                        'target_id' => protected_branch.id,
                                                        'target_type' => 'ProtectedBranch',
                                                        'custom_message' => action == :add ? /Added/ : /Unprotected/,
                                                        'ip_address' => ip_address,
                                                        'created_at' => anything)
                                                     )
        end

        it_behaves_like 'sends correct event type in audit event stream' do
          let(:subject) { service.execute }

          let_it_be(:event_type) { event_type }
        end
      end
    end

    include_examples 'loggable', :add, 'protected_branch_created'
    include_examples 'loggable', :remove, 'protected_branch_removed'

    context 'when not licensed' do
      let(:service) { described_class.new(author, protected_branch, :add) }

      before do
        stub_licensed_features(audit_events: false,
                               extended_audit_events: false,
                               admin_audit_log: false)
      end

      it "doesn't create an event or log to a file", :aggregate_failures do
        expect(service).not_to receive(:file_logger)

        expect { service.execute }.not_to change(AuditEvent, :count)
      end
    end
  end
end
