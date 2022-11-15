# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProjectChangesAuditor do
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
      stub_licensed_features(extended_audit_events: true)
    end

    describe 'non audit changes' do
      it 'does not call the audit event service' do
        project.update!(description: 'new description')

        expect { auditor_instance.execute }.not_to change(AuditEvent, :count)
      end
    end

    describe 'audit changes' do
      it 'creates an event when the visibility change' do
        project.update!(visibility_level: 20)

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.details[:change]).to eq 'visibility'
      end

      context 'when project name is updated' do
        it "logs project_name_updated event" do
          old_project_name = project.full_name.to_s

          project.update!(name: 'newname')

          expect(Gitlab::Audit::Auditor).to receive(:audit).with(
            {
              name: 'project_name_updated',
              author: user,
              scope: project,
              target: project,
              message: "Changed name from #{old_project_name} to #{project.full_name}",
              additional_details: {
                change: "name",
                from: old_project_name,
                target_details: project.full_path.to_s,
                to: project.full_name.to_s
              },
              target_details: project.full_path.to_s
            }
          ).and_call_original

          auditor_instance.execute
        end
      end

      context 'when project path is updated' do
        it "logs project_path_updated event" do
          project.update!(path: 'newpath')

          expect(Gitlab::Audit::Auditor).to receive(:audit).with(
            {
              name: 'project_path_updated',
              author: user,
              scope: project,
              target: project,
              message: "Changed path to #{project.full_path}",
              additional_details: {
                change: "path",
                from: "",
                target_details: project.full_path.to_s,
                to: project.full_path.to_s
              },
              target_details: project.full_path.to_s
            }
          ).and_call_original

          auditor_instance.execute
        end
      end

      it 'creates an event when the namespace change' do
        new_namespace = create(:namespace)

        project.update!(namespace: new_namespace)

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.details[:change]).to eq 'namespace'
      end

      it 'creates an event when the repository size limit changes' do
        project.update!(repository_size_limit: 100)

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.details[:change]).to eq 'repository_size_limit'
      end

      it 'creates an event when the packages enabled setting changes' do
        project.update!(packages_enabled: false)

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(2)
        expect(AuditEvent.last(2).map { |e| e.details[:change] })
          .to eq %w[packages_enabled package_registry_access_level]
      end

      it 'creates an event when the merge requests template changes' do
        project.update!(merge_requests_template: 'I am a merge request template')

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.details[:change]).to eq 'merge_requests_template'
        expect(AuditEvent.last.details).to include({
                                                     change: 'merge_requests_template',
                                                     from: nil,
                                                     to: 'I am a merge request template'
                                                   })
      end

      it 'creates an event when the merge requests author approval changes' do
        project.update!(merge_requests_author_approval: true)

        aggregate_failures do
          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
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
          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include(
            change: 'prevent merge request approval from committers',
            from: true,
            to: false
          )
        end
      end

      it 'creates an event when the reset approvals on push changes' do
        project.update!(reset_approvals_on_push: true)

        aggregate_failures do
          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
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
          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
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
          expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include(
            change: 'prevent users from modifying MR approval rules in merge requests',
            from: false,
            to: true
          )
        end
      end

      context 'when auditable boolean column is changed' do
        columns = %w[resolve_outdated_diff_discussions printing_merge_request_link_enabled
                     remove_source_branch_after_merge only_allow_merge_if_pipeline_succeeds
                     only_allow_merge_if_all_discussions_are_resolved]
        columns.each do |column|
          where(:prev_value, :new_value) do
            true  | false
            false | true
          end

          before do
            project.update_attribute(column, prev_value)
          end

          with_them do
            it 'creates an audit event' do
              project.update_attribute(column, new_value)

              expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
              expect(AuditEvent.last.details).to include({
                                                           change: column,
                                                           from: prev_value,
                                                           to: new_value
                                                         })
            end
          end
        end
      end

      it 'creates an event when suggestion_commit_message change' do
        previous_value = project.suggestion_commit_message
        new_value = "I'm a suggested commit message"
        project.update!(suggestion_commit_message: new_value)

        expect { auditor_instance.execute }.to change(AuditEvent, :count).by(1)
        expect(AuditEvent.last.details).to include({
                                                     change: 'suggestion_commit_message',
                                                     from: previous_value,
                                                     to: new_value
                                                   })
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
        end
      end
    end
  end
end
