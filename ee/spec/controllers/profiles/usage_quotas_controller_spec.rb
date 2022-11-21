# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::UsageQuotasController, feature_category: :purchase do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    it 'renders usage quota page' do
      get :index

      expect(subject).to render_template(:index)
    end
  end
end
