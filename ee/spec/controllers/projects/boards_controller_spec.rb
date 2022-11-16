# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BoardsController, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user)    { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it_behaves_like 'pushes wip limits to frontend' do
      let(:parent) { project }
      let(:params) { { namespace_id: parent.namespace, project_id: parent } }
    end
  end
end
