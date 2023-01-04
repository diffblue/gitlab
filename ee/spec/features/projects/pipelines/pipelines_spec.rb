# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Pipelines', :js, feature_category: :continuous_integration do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    sign_in(user)

    project.add_developer(user)
  end

  describe 'GET /:project/-/pipelines' do
    describe 'when namespace is in read-only mode' do
      it 'does not render Run pipeline and CI lint link' do
        allow_next_found_instance_of(Namespace) do |instance|
          allow(instance).to receive(:read_only?).and_return(true)
        end

        visit project_pipelines_path(project)
        wait_for_requests
        expect(page).to have_content('Show Pipeline ID')
        expect(page).not_to have_link('CI lint')
        expect(page).not_to have_link('Run pipeline')
      end
    end
  end

  describe 'GET /:project/-/pipelines/new' do
    describe 'when namespace is in read-only mode' do
      it 'renders 404' do
        allow_next_found_instance_of(Namespace) do |instance|
          allow(instance).to receive(:read_only?).and_return(true)
        end

        visit new_project_pipeline_path(project)
        expect(page).to have_content('Page Not Found')
      end
    end
  end
end
