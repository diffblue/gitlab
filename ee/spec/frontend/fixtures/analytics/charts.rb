# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include JavaScriptFixturesHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:user) { create(:user, :admin) }

  describe Groups::Analytics::TasksByTypeController, type: :controller do
    render_views

    let_it_be(:labels) { create_list(:group_label, 3, group: group) }

    before do
      2.times do |i|
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [labels[0]])
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [labels[1]])
        create(:labeled_issue, created_at: i.days.ago, project: create(:project, group: group), labels: [labels[2]])
      end

      stub_licensed_features(type_of_work_analytics: true)

      group.add_maintainer(user)

      sign_in(user)
    end

    it 'analytics/charts/type_of_work/tasks_by_type.json' do
      params = {
        group_id: group.full_path,
        label_names: labels.map(&:name),
        created_after: 10.days.ago,
        subject: 'Issue'
      }

      get(:show, params: params, format: :json)

      expect(response).to have_gitlab_http_status(:success)
    end
  end
end
