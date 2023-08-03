# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'devise/confirmations/almost_there', feature_category: :user_management do
  let_it_be(:template) { 'devise/confirmations/almost_there' }

  it_behaves_like 'page with unconfirmed user deletion information'
end
