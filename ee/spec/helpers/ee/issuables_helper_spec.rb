# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuablesHelper, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  describe '#issuable_initial_data' do
    let(:permission) { true }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(permission)
      stub_commonmark_sourcepos_disabled
    end

    context 'for an epic' do
      let_it_be(:epic) { create(:epic, author: user, description: 'epic text', confidential: true) }

      let(:expected_data) do
        {
          canAdmin: permission,
          canAdminRelation: permission,
          canDestroy: permission,
          canUpdate: permission,
          confidential: epic.confidential,
          endpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}",
          epicLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/links",
          epicsWebUrl: "/groups/#{@group.full_path}/-/epics",
          fullPath: @group.full_path,
          groupPath: @group.path,
          hasIssueWeightsFeature: nil,
          hasIterationsFeature: nil,
          state: epic.state,
          initialDescriptionHtml: '<p data-sourcepos="1:1-1:9" dir="auto">epic text</p>',
          initialDescriptionText: 'epic text',
          initialTaskCompletionStatus: { completed_count: 0, count: 0 },
          initialTitleHtml: epic.title,
          initialTitleText: epic.title,
          issuableRef: "&#{epic.iid}",
          issuableTemplateNamesPath: '',
          issueLinksEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}/issues",
          issuesWebUrl: "/groups/#{@group.full_path}/-/issues",
          lockVersion: epic.lock_version,
          markdownDocsPath: '/help/user/markdown',
          markdownPreviewPath: "/groups/#{@group.full_path}/preview_markdown?target_id=#{epic.iid}&target_type=Epic",
          projectsEndpoint: "/api/v4/groups/#{@group.id}/projects",
          updateEndpoint: "/groups/#{@group.full_path}/-/epics/#{epic.iid}.json"
        }
      end

      before do
        @group = epic.group
      end

      it 'returns the correct data when permissions allowed' do
        expect(helper.issuable_initial_data(epic)).to eq(expected_data)
      end

      context 'when permissions denied' do
        let(:permission) { false }

        it 'returns the correct data' do
          expect(helper.issuable_initial_data(epic)).to eq(expected_data)
        end
      end
    end

    context 'for an issue' do
      let_it_be(:issue) { create(:issue, author: user, description: 'issue text') }

      before do
        allow(issue.project).to receive(:licensed_feature_available?).and_return(true)
      end

      it 'returns the correct data' do
        @project = issue.project

        expected_data = {
          canAdmin: true,
          canAdminRelation: true,
          hasIssueWeightsFeature: true,
          hasIterationsFeature: true,
          publishedIncidentUrl: nil
        }
        expect(helper.issuable_initial_data(issue)).to include(expected_data)
      end

      context 'when published to a configured status page' do
        it 'returns the correct data that includes publishedIncidentUrl' do
          @project = issue.project

          expect(Gitlab::StatusPage::Storage).to receive(:details_url).with(issue).and_return('http://status.com')
          expect(helper.issuable_initial_data(issue)).to include(
            publishedIncidentUrl: 'http://status.com'
          )
        end
      end

      describe '#promotedToEpicUrl' do
        let(:issue) { create(:issue, author: user) }
        let(:epic) { create(:epic, author: user) }

        before do
          assign(:project, issue.project)
        end

        context 'when issue is promoted' do
          before do
            allow(issue).to receive(:promoted?).and_return(true)
            allow(issue).to receive(:promoted_to_epic).and_return(epic)
          end

          it 'returns url' do
            expect(helper.issuable_initial_data(issue)[:promotedToEpicUrl]).to be_truthy
          end
        end

        context 'when issue is not promoted' do
          before do
            allow(issue).to receive(:promoted?).and_return(false)
          end

          it 'returns nil' do
            expect(helper.issuable_initial_data(issue)[:promotedToEpicUrl]).to be_nil
          end
        end
      end
    end

    context 'for an incident' do
      let_it_be(:issue) { create(:issue, :incident, author: user, description: 'issue text') }

      let(:params) do
        ActionController::Parameters.new({
          controller: "projects/issues",
          action: "show",
          namespace_id: "foo",
          project_id: "bar",
          id: issue.iid,
          incident_tab: 'timeline'
        }).permit!
      end

      before do
        allow(helper).to receive(:safe_params).and_return(params)
      end

      context 'default state' do
        it 'returns the correct data' do
          @project = issue.project

          expect(helper.issuable_initial_data(issue)).to include(uploadMetricsFeatureAvailable: "false")
          expect(helper.issuable_initial_data(issue)).to include(canUpdateTimelineEvent: permission)
        end
      end

      context 'when incident metric upload is available' do
        before do
          stub_licensed_features(incident_metric_upload: true)
        end

        it 'correctly returns uploadMetricsFeatureAvailable as true' do
          @project = issue.project

          expect(helper.issuable_initial_data(issue)).to include(uploadMetricsFeatureAvailable: "true")
        end
      end
    end
  end
end
