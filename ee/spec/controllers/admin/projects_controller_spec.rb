# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ProjectsController, :geo, feature_category: :projects do
  include EE::GeoHelpers

  let_it_be(:geo_primary) { create(:geo_node, :primary) }

  let!(:project_registry) { create(:geo_project_registry) }
  let(:project) { project_registry.project }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects/:id' do
    subject { get :show, params: { namespace_id: project.namespace.path, id: project.path } }

    render_views

    it 'includes Geo Status widget partial' do
      expect(subject).to have_gitlab_http_status(:ok)
      expect(subject.body).to match(project.name)
      expect(subject).to render_template(partial: 'admin/projects/_geo_status_widget')
    end

    context 'when Geo is enabled and is a secondary node' do
      before do
        stub_current_geo_node(create(:geo_node))
      end

      it 'renders Geo Status widget' do
        expect(subject.body).to match('Geo Status')
      end

      it 'displays a different read-only message based on skip_readonly_message' do
        expect(subject.body).to match('You may be able to make a limited amount of changes or perform a limited amount of actions on this page')
        expect(subject.body).to include(geo_primary.url)
      end
    end

    context 'without Geo enabled' do
      it 'doesnt render Geo Status widget' do
        expect(subject.body).not_to match('Geo Status')
      end
    end
  end
end
