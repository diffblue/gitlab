# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Compliance Dashboard', :js do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, :public, namespace: group) }
  let_it_be(:project_2) { create(:project, :repository, :public, namespace: group) }

  before do
    stub_licensed_features(group_level_compliance_dashboard: true)
    group.add_owner(user)
    sign_in(user)
  end

  # TODO: This should be updated to fully test both with and without the feature flag once closer to feature completion
  # https://gitlab.com/gitlab-org/gitlab/-/issues/347302
  context 'when compliance_violations_report feature is disabled' do
    before do
      stub_feature_flags(compliance_violations_report: false)
      visit group_security_compliance_dashboard_path(group)
    end

    context 'when there are no merge requests' do
      it 'shows an empty state' do
        expect(page).to have_selector('.empty-state')
      end
    end

    context 'when there are merge requests' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project, state: :merged, merge_commit_sha: 'b71a6483b96dc303b66fdcaa212d9db6b10591ce') }
      let_it_be(:merge_request_2) { create(:merge_request, source_project: project_2, state: :merged, merge_commit_sha: '24327319d067f4101cd3edd36d023ab5e49a8579') }

      before_all do
        create(:event, :merged, project: project, target: merge_request, author: user, created_at: 10.minutes.ago)
        create(:event, :merged, project: project_2, target: merge_request_2, author: user, created_at: 15.minutes.ago)
      end

      it 'shows merge requests with details' do
        expect(page).to have_link(merge_request.title)
        expect(page).to have_content('merged 10 minutes ago')
        expect(page).to have_content('no approvers')
      end

      context 'chain of custody report' do
        it 'exports a merge commit-specific CSV' do
          find('.dropdown-toggle').click

          requests = inspect_requests do
            page.within('.dropdown-menu') do
              find('input[name="commit_sha"]').set(merge_request.merge_commit_sha)
              find('button[type="submit"]').click
            end
          end

          csv_request = requests.find { |req| req.url.match(%r{.csv}) }

          expect(csv_request.response_headers['Content-Disposition']).to match(%r{.csv})
          expect(csv_request.response_headers['Content-Type']).to eq("text/csv; charset=utf-8")
          expect(csv_request.response_headers['Content-Transfer-Encoding']).to eq("binary")
          expect(csv_request.body).to match(%r{#{merge_request.merge_commit_sha}})
          expect(csv_request.body).not_to match(%r{#{merge_request_2.merge_commit_sha}})
        end
      end
    end
  end

  context 'when compliance_violations_report feature is enabled' do
    before do
      stub_feature_flags(compliance_violations_report: true)
      visit group_security_compliance_dashboard_path(group)
    end

    it 'shows the violations report table', :aggregate_failures do
      page.within('table') do
        expect(page).to have_content 'Severity'
        expect(page).to have_content 'Violation'
        expect(page).to have_content 'Merge request'
        expect(page).to have_content 'Date merged'
      end
    end
  end
end
