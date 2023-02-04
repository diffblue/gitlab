# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'groups autocomplete', feature_category: :subgroups do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, :private) }
  let_it_be(:epic) { create(:epic, group: group) }

  before_all do
    group.add_developer(user)
  end

  before do
    stub_licensed_features(epics: true)
    sign_in(user)
  end

  describe '#issues' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:test_case) { create(:quality_test_case, project: project) }

    where(:issue_types, :expected) do
      nil         | :test_case
      ''          | :test_case
      'invalid'   | []
      'test_case' | :test_case
    end

    with_them do
      it 'returns the correct response', :aggregate_failures do
        issues = Array(expected).flat_map { |sym| public_send(sym) }

        get issues_group_autocomplete_sources_path(group, issue_types: issue_types)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(issues.size)
        expect(json_response.map { |issue| issue['iid'] })
          .to match_array(issues.map(&:iid))
      end
    end
  end

  describe '#epics' do
    it 'returns 200 status' do
      get epics_group_autocomplete_sources_path(group)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns the correct response' do
      get epics_group_autocomplete_sources_path(group)

      expect(json_response).to be_an(Array)
      expect(json_response.first).to include(
        'iid' => epic.iid, 'title' => epic.title, 'reference' => epic.to_reference(epic.group)
      )
    end

    it 'avoids N+1 queries' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get epics_group_autocomplete_sources_path(group) }

      create_list(:epic, 3, group: group)

      expect do
        get epics_group_autocomplete_sources_path(group)
      end.not_to exceed_all_query_limit(control)
    end
  end

  describe '#iterations', :freeze_time, feature_category: :team_planning do
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:open_iteration) { create(:iteration, iterations_cadence: cadence) }
    let_it_be(:closed_iteration) { create(:iteration, :closed, iterations_cadence: cadence) }

    context 'when iterations feature is disabled' do
      before do
        stub_licensed_features(iterations: false)
      end

      it 'returns 404 status' do
        visit

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when iterations feature is enabled' do
      before do
        stub_licensed_features(iterations: true)
      end

      describe '#iterations' do
        it 'returns the correct response', :aggregate_failures do
          iteration_json_response = {
            'id' => open_iteration.id,
            'title' => open_iteration.display_text,
            'reference' => open_iteration.to_reference
          }

          visit

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to be_an(Array)
          expect(json_response.count).to eq(1)
          expect(json_response.first).to include(iteration_json_response)
        end
      end

      it 'avoids N+1 queries', :use_sql_query_cache do
        control = ActiveRecord::QueryRecorder.new(skip_cached: false) { visit }

        create(:iteration, iterations_cadence: cadence)

        expect { visit }.not_to exceed_all_query_limit(control)
      end
    end

    def visit
      get iterations_group_autocomplete_sources_path(group)
    end
  end

  describe '#vulnerabilities' do
    let_it_be_with_reload(:project) { create(:project, :private, group: group) }
    let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }

    before do
      project.add_developer(user)
      stub_licensed_features(security_dashboard: true)
    end

    it 'returns 200 status' do
      get vulnerabilities_group_autocomplete_sources_path(group)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns the correct response', :aggregate_failures do
      get vulnerabilities_group_autocomplete_sources_path(group)

      expect(json_response).to be_an(Array)
      expect(json_response.first).to include(
        'id' => vulnerability.id, 'title' => vulnerability.title
      )
    end
  end

  describe '#commands' do
    it 'returns 200 status' do
      get commands_group_autocomplete_sources_path(group, type: 'Epic', type_id: epic.iid)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns the correct response' do
      get commands_group_autocomplete_sources_path(group, type: 'Epic', type_id: epic.iid)

      expect(json_response).to be_an(Array)
      expect(json_response).to include(
        {
          'name' => 'close', 'aliases' => [], 'description' => 'Close this epic',
          'params' => [], 'warning' => '', 'icon' => ''
        }
      )
    end

    it 'handles new epics' do
      get commands_group_autocomplete_sources_path(group, type: 'Epic', type_id: nil)

      expect(json_response).to be_an(Array)
      expect(json_response).to include(
        {
          'name' => 'cc', 'aliases' => [], 'description' => 'CC',
          'params' => ['@user'], 'warning' => '', 'icon' => ''
        }
      )
    end
  end
end
