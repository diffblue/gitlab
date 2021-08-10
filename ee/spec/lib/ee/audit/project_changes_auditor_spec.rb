# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Audit::ProjectChangesAuditor do
  describe '.audit_changes' do
    let(:user) { create(:user) }
    let(:project) do
      create(
        :project,
        visibility_level: 0,
        name: 'interesting name',
        path: 'interesting-path',
        repository_size_limit: 10,
        packages_enabled: true,
        merge_requests_author_approval: false,
        merge_requests_disable_committers_approval: true,
        reset_approvals_on_push: false,
        disable_overriding_approvers_per_merge_request: false,
        require_password_to_approve: false
      )
    end

    subject(:foo_instance) { described_class.new(user, project) }

    before do
      project.reload
      stub_licensed_features(extended_audit_events: true)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        project.update!(description: 'new description')

        expect { foo_instance.execute }.not_to change { AuditEvent.count }
      end
    end

    describe 'auditing compliance framework changes' do
      context 'when a project has no compliance framework' do
        context 'when the framework is changed' do
          let_it_be(:framework) { create(:compliance_framework) }

          before do
            project.update!(compliance_management_framework: framework)
          end

          it 'adds an audit event' do
            expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
            expect(AuditEvent.last.details).to include({
              change: 'compliance framework',
              from: 'None',
              to: 'GDPR'
            })
          end

          context 'when the framework is removed' do
            before do
              project.update!(compliance_management_framework: nil)
            end

            it 'adds an audit event' do
              expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
              expect(AuditEvent.last.details).to include({
                custom_message: "Unassigned project compliance framework"
              })
            end
          end

          context 'when the framework is changed again' do
            before do
              project.update!(compliance_management_framework: create(:compliance_framework, namespace: project.namespace, name: 'SOX'))
            end

            it 'adds an audit event' do
              expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
              expect(AuditEvent.last.details).to include({
                change: 'compliance framework',
                from: 'GDPR',
                to: 'SOX'
              })
            end
          end
        end

        context 'when the framework is not changed' do
          before do
            project.update!(description: 'This is a description of a project')
          end

          it 'does not add an audit event' do
            expect { foo_instance.execute }.not_to change { AuditEvent.count }
          end
        end
      end
    end

    describe 'audit changes' do
      it 'creates an event when the visibility change' do
        project.update!(visibility_level: 20)

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'visibility'
      end

      it 'creates an event when the name change' do
        project.update!(name: 'new name')

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'name'
      end

      it 'creates an event when the path change' do
        project.update!(path: 'newpath')

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'path'
      end

      it 'creates an event when the namespace change' do
        new_namespace = create(:namespace)

        project.update!(namespace: new_namespace)

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'namespace'
      end

      it 'creates an event when the repository size limit changes' do
        project.update!(repository_size_limit: 100)

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'repository_size_limit'
      end

      it 'creates an event when the packages enabled setting changes' do
        project.update!(packages_enabled: false)

        expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
        expect(AuditEvent.last.details[:change]).to eq 'packages_enabled'
      end

      it 'creates an event when the merge requests author approval changes' do
        project.update!(merge_requests_author_approval: true)

        aggregate_failures do
          expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include(
            change: 'prevent merge request approval from authors',
            from: true,
            to: false
          )
        end
      end

      it 'creates an event when the merge requests committers approval changes' do
        project.update!(merge_requests_disable_committers_approval: false)

        aggregate_failures do
          expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include(
            change: 'prevent merge request approval from reviewers',
            from: true,
            to: false
          )
        end
      end

      it 'creates an event when the reset approvals on push changes' do
        project.update!(reset_approvals_on_push: true)

        aggregate_failures do
          expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include(
            change: 'require new approvals when new commits are added to an MR',
            from: false,
            to: true
          )
        end
      end

      it 'creates an event when the require password to approve changes' do
        project.update!(require_password_to_approve: true)

        aggregate_failures do
          expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include(
            change: 'require user password for approvals',
            from: false,
            to: true
          )
        end
      end

      it 'creates an event when the disable overriding approvers per merge request changes' do
        project.update!(disable_overriding_approvers_per_merge_request: true)

        aggregate_failures do
          expect { foo_instance.execute }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include(
            change: 'prevent users from modifying MR approval rules in merge requests',
            from: false,
            to: true
          )
        end
      end
    end
  end
end
