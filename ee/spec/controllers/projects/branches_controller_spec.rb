# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BranchesController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:user) { project.first_owner }

  before do
    allow(project).to receive(:branches).and_return(['master'])
    controller.instance_variable_set(:@project, project)

    sign_in(user)
  end

  describe 'GET #index' do
    context 'for mirrored projects with diverged branch' do
      render_views

      before do
        create(:import_state, :mirror, :finished, project: project, last_successful_update_at: Time.current)
        allow(project.repository).to receive(:diverged_from_upstream?).and_return(true)
      end

      it 'renders the diverged from upstream partial' do
        get :index, format: :html, params: {
          namespace_id: project.namespace,
          project_id: project,
          state: 'all'
        }

        expect(controller).to render_template('projects/branches/_diverged_from_upstream')
        expect(response.body).to match(/diverged from upstream/)
      end
    end
  end
end
