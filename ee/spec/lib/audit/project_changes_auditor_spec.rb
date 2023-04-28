# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProjectChangesAuditor, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax
  describe '.audit_changes' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    let(:project) do
      create(
        :project,
        group: group,
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

    subject(:auditor_instance) { described_class.new(user, project) }

    before do
      project.reload
      stub_licensed_features(extended_audit_events: true, external_audit_events: true)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    shared_examples 'project_audit_events_from_to' do
      it 'calls auditor' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(
          {
            name: event.to_s,
            author: user,
            scope: project,
            target: project,
            message: "Changed #{change} from #{change_from} to #{change_to}",
            additional_details: {
              change: change.to_s,
              from: change_from,
              target_details: project.full_path.to_s,
              to: change_to
            },
            target_details: project.full_path.to_s
          }
        ).and_call_original

        auditor_instance.execute
      end
    end

    shared_examples 'project_audit_events_to' do
      it 'calls auditor' do
        expect(Gitlab::Audit::Auditor).to receive(:audit).with(
          {
            name: event.to_s,
            author: user,
            scope: project,
            target: project,
            message: "Changed #{change} to #{change_to}",
            additional_details: {
              change: change.to_s,
              from: change_from,
              target_details: project.full_path.to_s,
              to: change_to
            },
            target_details: project.full_path.to_s
          }
        ).and_call_original

        auditor_instance.execute
      end
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        project.update!(description: 'new description')

        expect { auditor_instance.execute }.not_to change(AuditEvent, :count)
      end
    end

    describe 'audit changes' do
      context 'when project visibility_level is updated' do
        let(:change) { "visibility_level" }
        let(:event) { "project_visibility_level_updated" }
        let(:change_from) { "Private" }
        let(:change_to) { "Public" }

        before do
          project.update!(visibility_level: 20)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project name is updated' do
        let(:change) { "name" }
        let(:event) { "project_name_updated" }
        let(:change_from) { "#{group.name} / interesting name" }
        let(:change_to) { project.full_name }

        before do
          project.update!(name: 'newname')
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project path is updated' do
        let(:change) { "path" }
        let(:event) { "project_path_updated" }
        let(:change_from) { "" }
        let(:change_to) { project.full_path }

        before do
          project.update!(path: 'newpath')
        end

        it_behaves_like 'project_audit_events_to'
      end

      context 'when project namespace is updated' do
        let(:change) { "namespace" }
        let(:event) { "project_namespace_updated" }
        let(:change_from) { project.old_path_with_namespace }
        let(:change_to) { project.full_path }

        before do
          new_namespace = create(:namespace)
          project.update!(namespace: new_namespace)
        end

        it_behaves_like 'project_audit_events_to'
      end

      context 'when project repository size limit is updated' do
        let(:change) { "repository_size_limit" }
        let(:event) { "project_repository_size_limit_updated" }
        let(:change_from) { 10 }
        let(:change_to) { 100  }

        before do
          project.update!(repository_size_limit: 100)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project packages enabled setting changes is updated' do
        it "logs project_packages_enabled_updated event" do
          project.update!(packages_enabled: false)

          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(2)
          expect(AuditEvent.last(2).map { |e| e.details[:change] })
          .to eq %w[packages_enabled package_registry_access_level]
        end
      end

      context 'when project merge_requests_template is updated' do
        let(:change) { "merge_requests_template" }
        let(:event) { "project_merge_requests_template_updated" }
        let(:change_from) { nil }
        let(:change_to) { 'I am a merge request template' }

        before do
          project.update!(merge_requests_template: 'I am a merge request template')
        end

        it_behaves_like 'project_audit_events_to'
      end

      context 'when project merge_requests_author_approval is updated' do
        let(:change) { "prevent merge request approval from authors" }
        let(:event) { "project_merge_requests_author_approval_updated" }
        let(:change_from) { true }
        let(:change_to) { false }

        before do
          project.update!(merge_requests_author_approval: true)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project merge_requests_disable_committers_approval is updated' do
        let(:change) { "prevent merge request approval from committers" }
        let(:event) { "project_merge_requests_disable_committers_approval_updated" }
        let(:change_from) { true }
        let(:change_to) { false }

        before do
          project.update!(merge_requests_disable_committers_approval: false)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project reset_approvals_on_push is updated' do
        let(:change) { "require new approvals when new commits are added to an MR" }
        let(:event) { "project_reset_approvals_on_push_updated" }
        let(:change_from) { false }
        let(:change_to) { true }

        before do
          project.update!(reset_approvals_on_push: true)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project require_password_to_approve is updated' do
        let(:change) { "require user password for approvals" }
        let(:event) { "project_require_password_to_approve_updated" }
        let(:change_from) { false }
        let(:change_to) { true }

        before do
          project.update!(require_password_to_approve: true)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when project disable_overriding_approvers_per_merge_request is updated' do
        let(:change) { "prevent users from modifying MR approval rules in merge requests" }
        let(:event) { "project_disable_overriding_approvers_per_merge_request_updated" }
        let(:change_from) { false }
        let(:change_to) { true }

        before do
          project.update!(disable_overriding_approvers_per_merge_request: true)
        end

        it_behaves_like 'project_audit_events_from_to'
      end

      context 'when auditable boolean column is changed' do
        columns = %w[resolve_outdated_diff_discussions printing_merge_request_link_enabled
                     remove_source_branch_after_merge only_allow_merge_if_pipeline_succeeds
                     only_allow_merge_if_all_discussions_are_resolved]
        columns.each do |column|
          context "with #{column}" do
            where(:prev_value, :new_value) do
              true  | false
              false | true
            end

            with_them do
              before do
                project.update_attribute(column, prev_value)
                project.update_attribute(column, new_value)
              end

              it 'creates an audit event' do
                expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
                expect(AuditEvent.last.details).to include({
                                                            change: column,
                                                            from: prev_value,
                                                            to: new_value
                                                          })
              end

              it 'streams correct audit event', :aggregate_failures do
                event_name = "project_#{column}_updated"
                expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
                  .with(event_name, anything, anything)
                subject.execute
              end
            end
          end
        end
      end

      context 'when project suggestion_commit_message is updated' do
        let(:change) { "suggestion_commit_message" }
        let(:event) { "project_suggestion_commit_message_updated" }
        let(:change_from) { nil }
        let(:change_to) { "I'm a suggested commit message" }

        before do
          project.update!(suggestion_commit_message: "I'm a suggested commit message")
        end

        it_behaves_like 'project_audit_events_to'
      end

      it 'does not create an event when suggestion_commit_message change from nil to empty string' do
        project.update!(suggestion_commit_message: "")

        expect { auditor_instance.execute }.not_to change(AuditEvent, :count)
      end

      context 'when merge method is changed from Merge' do
        where(:ff, :rebase, :method) do
          true  | true  | 'Fast-forward'
          true  | false | 'Fast-forward'
          false | true  | 'Rebase merge'
        end

        before do
          project.update!(merge_requests_ff_only_enabled: false, merge_requests_rebase_enabled: false)
        end

        with_them do
          it 'creates an audit event' do
            project.update!(merge_requests_ff_only_enabled: ff, merge_requests_rebase_enabled: rebase)

            expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
            expect(AuditEvent.last.details).to include({
                                                         custom_message: "Changed merge method to #{method}"
                                                       })
          end

          it 'streams correct audit event' do
            project.update!(merge_requests_ff_only_enabled: ff, merge_requests_rebase_enabled: rebase)

            expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
                .with("project_merge_method_updated", anything, anything)
            auditor_instance.execute
          end
        end
      end

      context 'when merge method is changed to Merge' do
        where(:ff, :rebase) do
          true  | true
          true  | false
          false | true
        end

        with_them do
          before do
            project.update!(merge_requests_ff_only_enabled: ff, merge_requests_rebase_enabled: rebase)
          end

          it 'creates an Merge method audit event' do
            project.update!(merge_requests_ff_only_enabled: false, merge_requests_rebase_enabled: false)

            expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
            expect(AuditEvent.last.details).to include({
                                                         custom_message: "Changed merge method to Merge"
                                                       })
          end

          it 'streams correct audit event' do
            project.update!(merge_requests_ff_only_enabled: false, merge_requests_rebase_enabled: false)

            expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
              .with("project_merge_method_updated", anything, anything)
            auditor_instance.execute
          end
        end
      end
    end
  end
end
