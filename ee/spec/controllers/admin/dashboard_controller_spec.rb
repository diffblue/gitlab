# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::DashboardController, feature_category: :shared do
  describe '#index' do
    it "allows an admin user to access the page" do
      sign_in(create(:user, :admin))

      get :index

      expect(response).to have_gitlab_http_status(:ok)
    end

    it "does not allow an auditor user to access the page" do
      sign_in(create(:user, :auditor))

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it "does not allow a regular user to access the page" do
      sign_in(create(:user))

      get :index

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
