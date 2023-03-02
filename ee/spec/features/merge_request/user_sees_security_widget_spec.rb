# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Merge request > User sees security widget",
  :js, :sidekiq_inline, :use_clean_rails_memory_store_caching,
  feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, :simple, :with_sast_reports, source_project: project) }
  let(:user) { project.creator }

  let(:feature_branch_start_sha) { "ae73cb07c9eeaf35924a10f713b364d32b2dd34f" }
  let(:mr_widget_app_selector) { "[data-testid='mr-widget-app']" }
  let(:merge_request_path) { project_merge_request_path(project, merge_request) }

  before do
    stub_licensed_features(
      security_dashboard: true,
      sast: true
    )

    project.add_developer(user)
    sign_in(user)
  end

  it "shows the security widget" do
    visit(merge_request_path)

    page.within(mr_widget_app_selector) do
      expect(page).to have_content(
        "Security scanning detected 5 new potential vulnerabilities"
      )

      click_on 'Show details'

      expect(page).to have_content 'Hard coded key'
    end
  end

  context "when vulnerabilities in an MR have already been detected on main" do
    let!(:ci_pipeline) do
      create(
        :ci_pipeline,
        :success,
        :with_sast_report,
        project: project,
        sha: feature_branch_start_sha
      )
    end

    it "does not show them as new vulnerabilities" do
      visit(merge_request_path)

      page.within(mr_widget_app_selector) do
        expect(page).to have_content(
          "Security scanning detected no new potential vulnerabilities"
        )
      end
    end
  end

  context "when master detects vulnerabilities in a child pipeline" do
    context 'and merge request detects the same vulnerabilities not in a child pipeline' do
      let(:parent_pipeline) do
        create(
          :ci_pipeline,
          :success,
          project: project,
          sha: feature_branch_start_sha
        )
      end

      let!(:child_pipeline) do
        create(
          :ci_pipeline,
          :success,
          :with_sast_report,
          project: project,
          child_of: parent_pipeline,
          sha: feature_branch_start_sha
        )
      end

      it "does not show them as new vulnerabilities" do
        visit(merge_request_path)

        page.within(mr_widget_app_selector) do
          expect(page).to have_content(
            "Security scanning detected no new potential vulnerabilities"
          )
        end
      end
    end
  end
end
