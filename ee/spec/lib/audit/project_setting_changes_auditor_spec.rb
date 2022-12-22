# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProjectSettingChangesAuditor, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:destination) { create(:external_audit_event_destination, group: group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:project_setting_changes_auditor) { described_class.new(user, project.project_setting, project) }

    before do
      stub_licensed_features(extended_audit_events: true, external_audit_events: true)
    end

    context 'when project setting is updated' do
      options = ProjectSetting.squash_options.keys
      options.each do |prev_value|
        options.each do |new_value|
          context 'when squash option is changed' do
            before do
              project.project_setting.update!(squash_option: prev_value)
            end

            if new_value != prev_value
              it 'creates an audit event' do
                project.project_setting.update!(squash_option: new_value)

                expect { project_setting_changes_auditor.execute }.to change(AuditEvent, :count).by(1)
                expect(AuditEvent.last.details).to include(
                  {
                    custom_message: "Changed squash option to #{project.project_setting.human_squash_option}"
                  })
              end

              it 'streams correct audit event stream' do
                project.project_setting.update!(squash_option: new_value)

                expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
                  'squash_option_updated', anything, anything)

                project_setting_changes_auditor.execute
              end
            else
              it 'does not create audit event' do
                project.project_setting.update!(squash_option: new_value)
                expect { project_setting_changes_auditor.execute }.to not_change { AuditEvent.count }
              end
            end
          end
        end
      end

      context 'when allow_merge_on_skipped_pipeline is changed' do
        where(:prev_value, :new_value) do
          true  | false
          false | true
        end

        with_them do
          before do
            project.project_setting.update!(allow_merge_on_skipped_pipeline: prev_value)
          end

          it 'creates an audit event' do
            project.project_setting.update!(allow_merge_on_skipped_pipeline: new_value)

            expect { project_setting_changes_auditor.execute }.to change(AuditEvent, :count).by(1)
            expect(AuditEvent.last.details).to include({
                                                         change: 'allow_merge_on_skipped_pipeline',
                                                         from: prev_value,
                                                         to: new_value
                                                       })
          end

          it 'streams correct audit event stream' do
            project.project_setting.update!(allow_merge_on_skipped_pipeline: new_value)

            expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
              'allow_merge_on_skipped_pipeline_updated', anything, anything)

            project_setting_changes_auditor.execute
          end
        end
      end

      context 'when squash_commit_template is changed' do
        before do
          project.project_setting.update!(squash_commit_template: 'old squash commit template')
        end

        it 'creates an audit event' do
          project.project_setting.update!(squash_commit_template: 'new squash commit template')

          expect { project_setting_changes_auditor.execute }.to change(AuditEvent, :count).by(1)
          expect(AuditEvent.last.details).to include({
                                                       change: 'squash_commit_template',
                                                       from: 'old squash commit template',
                                                       to: 'new squash commit template'
                                                     })
        end

        it 'streams correct audit event stream' do
          project.project_setting.update!(squash_commit_template: 'new squash commit template')

          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
            'squash_commit_template_updated', anything, anything)

          project_setting_changes_auditor.execute
        end
      end

      context 'when merge_commit_template is changed' do
        before do
          project.project_setting.update!(merge_commit_template: 'old merge commit template')
        end

        it 'creates an audit event' do
          project.project_setting.update!(merge_commit_template: 'new merge commit template')

          aggregate_failures do
            expect { project_setting_changes_auditor.execute }.to change(AuditEvent, :count).by(1)
            expect(AuditEvent.last.details).to include({
                                                         change: 'merge_commit_template',
                                                         from: 'old merge commit template',
                                                         to: 'new merge commit template'
                                                       })
          end
        end

        it 'streams correct audit event stream' do
          project.project_setting.update!(merge_commit_template: 'new merge commit template')

          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(
            'merge_commit_template_updated', anything, anything)

          project_setting_changes_auditor.execute
        end
      end
    end
  end
end
