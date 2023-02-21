# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadsController, feature_category: :system_access do
  let!(:user) { create(:user) }
  let!(:project) { create(:project) }

  describe "GET show" do
    context 'when viewing issuable metric images' do
      let(:incident) { create(:incident, project: project) }
      let(:metric_image) { create(:issuable_metric_image, issue: incident) }

      before do
        project.add_developer(user)
        sign_in(user)
      end

      it "responds with status 200" do
        get :show, params: { model: "issuable_metric_image", mounted_as: 'file', id: metric_image.id, filename: metric_image.filename }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
