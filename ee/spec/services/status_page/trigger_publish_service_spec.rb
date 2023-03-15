# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StatusPage::TriggerPublishService, feature_category: :incident_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, refind: true) { create(:project, :repository) }

  let(:service) { described_class.new(project, user, triggered_by, action: :update) }

  describe '#execute' do
    # Variables used by shared examples
    let(:execute) { subject }

    let_it_be(:status_page_setting, reload: true) do
      create(:status_page_setting, :enabled, project: project)
    end

    subject { service.execute }

    describe 'invalid action' do
      let(:service) { described_class.new(project, user, double(:issue), action: :something_invalid) }

      it 'raises an argument error and does not process' do
        expect(StatusPage::PublishWorker).not_to receive(:perform_async)

        expect { subject }.to raise_error(ArgumentError)
      end
    end

    describe 'triggered by issue' do
      let_it_be(:triggered_by, reload: true) { create(:issue, :published, project: project) }

      let(:issue_id) { triggered_by.id }

      using RSpec::Parameterized::TableSyntax

      where(:changes, :shared_example_name) do
        { weight: 23 }              | 'no trigger status page publish'
        { title: 'changed' }        | 'trigger status page publish'
        { description: 'changed' }  | 'trigger status page publish'
        { confidential: true }      | 'trigger status page publish'
      end

      with_them do
        include_examples params[:shared_example_name] do
          before do
            triggered_by.update!(changes)
          end
        end
      end

      context 'without changes' do
        include_examples 'no trigger status page publish'

        context 'with init action' do
          let(:service) { described_class.new(project, user, triggered_by, action: :init) }

          include_examples 'trigger status page publish'
        end
      end

      context 'when a confidential issue changes' do
        let(:triggered_by) { create(:issue, :confidential, project: project) }

        include_examples 'no trigger status page publish' do
          before do
            triggered_by.update!(title: 'changed')
          end
        end
      end

      context 'when a non-published issue changes' do
        let(:triggered_by) { create(:issue, project: project) }

        include_examples 'no trigger status page publish' do
          before do
            triggered_by.update!(title: 'changed')
          end
        end
      end

      context 'when closing an issue' do
        include_examples 'trigger status page publish' do
          before do
            # Mimic Issues::CloseService#close_issue
            triggered_by.close!
            triggered_by.update!(closed_by: user)
          end
        end
      end

      context 'when reopening an issue' do
        include_examples 'trigger status page publish' do
          let_it_be(:triggered_by) { create(:issue, :closed, :published, project: project) }

          before do
            triggered_by.reopen!
          end
        end
      end
    end

    describe 'triggered by note' do
      let(:issue_id) { triggered_by.noteable_id }
      let(:emoji_name) { Gitlab::StatusPage::AWARD_EMOJI }

      before do
        create(:award_emoji, user: user, name: emoji_name, awardable: triggered_by)
      end

      context 'for issues' do
        let_it_be(:triggered_by, refind: true) do
          create(:note_on_issue, project: project)
        end

        context 'without changes' do
          include_examples 'no trigger status page publish'
        end

        context 'when changed' do
          include_examples 'trigger status page publish' do
            before do
              triggered_by.update!(note: 'changed')
            end
          end
        end

        context 'when destroyed' do
          include_examples 'trigger status page publish' do
            before do
              triggered_by.destroy!
            end
          end
        end

        context 'as system note' do
          let_it_be(:triggered_by, reload: true) do
            create(:note_on_issue, :system, project: project)
          end

          include_examples 'no trigger status page publish' do
            before do
              triggered_by.update!(note: 'changed')
            end
          end
        end

        context 'without recognized emoji' do
          let(:emoji_name) { 'thumbsup' }

          context 'when changed' do
            include_examples 'no trigger status page publish' do
              before do
                triggered_by.update!(note: 'changed')
              end
            end
          end

          context 'when destroyed' do
            include_examples 'trigger status page publish' do
              before do
                triggered_by.destroy!
              end
            end
          end
        end
      end

      context 'for merge requests' do
        let_it_be(:triggered_by) do
          create(:note_on_merge_request, project: project)
        end

        context 'when changed' do
          include_examples 'no trigger status page publish' do
            before do
              triggered_by.update!(note: 'changed')
            end
          end
        end
      end
    end

    describe 'triggered by award emoji' do
      let(:emoji_name) { Gitlab::StatusPage::AWARD_EMOJI }
      let(:issue_id) { triggered_by.awardable.noteable_id }

      let(:triggered_by) do
        create(:award_emoji, name: emoji_name, awardable: awardable)
      end

      context 'for notes on issues' do
        let_it_be(:awardable) { create(:note_on_issue, project: project) }

        include_examples 'trigger status page publish'

        context 'without recognized emoji' do
          let(:emoji_name) { 'thumbsup' }

          include_examples 'no trigger status page publish'
        end
      end

      context 'for issues' do
        let_it_be(:awardable) { create(:issue, project: project) }

        include_examples 'no trigger status page publish'
      end

      context 'for notes on merge requests' do
        let_it_be(:awardable) { create(:note_on_merge_request, project: project) }

        include_examples 'no trigger status page publish'
      end
    end

    describe 'triggered by unsupported type' do
      context 'for some abitary type' do
        let(:triggered_by) { Object.new }

        include_context 'status page enabled'

        it 'raises ArgumentError' do
          expect { subject }
            .to raise_error(ArgumentError, 'unsupported trigger type Object')
        end
      end
    end

    context 'with eligable triggered_by' do
      let_it_be(:triggered_by) { create(:issue, :published, project: project) }

      let(:issue_id) { triggered_by.id }

      context 'when eligable' do
        include_examples 'trigger status page publish'
      end

      context 'when status page is missing' do
        include_examples 'no trigger status page publish' do
          before do
            project.status_page_setting.destroy!
            project.reload
          end
        end
      end

      context 'when status page is not enabled' do
        include_examples 'no trigger status page publish' do
          before do
            project.status_page_setting.update!(enabled: false)
          end
        end
      end

      context 'when license is not available' do
        include_examples 'no trigger status page publish' do
          before do
            stub_licensed_features(status_page: false)
          end
        end
      end

      context 'when user cannot publish status page' do
        include_examples 'no trigger status page publish' do
          before do
            project.add_reporter(user)
          end
        end
      end
    end
  end
end
