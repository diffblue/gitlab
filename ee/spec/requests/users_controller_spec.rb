# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersController, feature_category: :user_profile do
  let_it_be(:user) { create(:user) }

  before do
    sign_in user
  end

  describe '#available_group_templates' do
    subject(:perform_request) do
      get user_available_group_templates_path(user.username)
    end

    before do
      allow(Kaminari.config).to receive(:default_per_page).and_return(1)

      2.times do |i|
        group = create(:group, name: "group#{i}")
        subgroup = create(:group, parent: group, name: "subgroup#{i}")
        create(:project, group: subgroup)

        group.update!(custom_project_templates_group_id: subgroup.id)
        group.add_maintainer(user)
      end
    end

    it 'shows the first page of the pagination' do
      perform_request

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('group0')
      expect(response.body).not_to include('group1')
    end
  end
end
