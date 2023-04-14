# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TreeHelper, feature_category: :source_code_management do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { build_stubbed(:project, :repository) }
  let(:sha) { 'c1c67abbaf91f624347bb3ae96eabe3a1b742478' }

  let_it_be(:user) { build_stubbed(:user) }

  describe '#vue_file_list_data' do
    before do
      project.add_developer(user)
      allow(helper).to receive(:current_user).and_return(user)
      sign_in(user)
    end

    it 'returns a list of attributes related to the project' do
      expect(helper.vue_file_list_data(project, sha)).to include(
        project_path: project.full_path,
        project_short_path: project.path,
        ref: sha,
        escaped_ref: sha,
        full_name: project.name_with_namespace,
        resource_id: project.to_global_id,
        user_id: user.to_global_id,
        explain_code_available: 'false'
      )
    end
  end
end
