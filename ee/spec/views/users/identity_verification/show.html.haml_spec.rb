# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'user/identity_verification/show', feature_category: :onboarding do
  let_it_be(:template) { 'users/identity_verification/show' }
  let_it_be(:user) { create_default(:user) }

  before do
    assign(:user, user)
  end

  it_behaves_like 'page with unconfirmed user deletion information'
end
