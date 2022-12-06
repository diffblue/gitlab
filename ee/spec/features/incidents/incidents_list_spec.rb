# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Management index', :js, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project) }

  before_all do
    project.add_developer(developer)
  end

  before do
    sign_in(developer)
  end

  context 'when a developer displays the incident list' do
    it 'has expected columns' do
      visit project_incidents_path(project)
      wait_for_requests
      table = page.find('.gl-table')

      expect(table).to have_content('Severity')
      expect(table).to have_content('Incident')
      expect(table).to have_content('Status')
      expect(table).to have_content('Date created')
      expect(table).to have_content('Assignees')

      expect(table).not_to have_content('Time to SLA')
      expect(table).not_to have_content('Published')
    end

    context 'with SLA feature available' do
      before do
        stub_licensed_features(incident_sla: true)
      end

      it 'includes the SLA column' do
        visit project_incidents_path(project)
        wait_for_requests

        expect(page.find('.gl-table')).to have_content('Time to SLA')
      end
    end

    context 'with Status Page feature available' do
      before do
        stub_licensed_features(status_page: true)
      end

      it 'includes the Published column' do
        visit project_incidents_path(project)
        wait_for_requests

        expect(page.find('.gl-table')).to have_content('Published')
      end
    end
  end
end
