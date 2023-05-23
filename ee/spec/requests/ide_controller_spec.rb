# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdeController, feature_category: :web_ide do
  include ContentSecurityPolicyHelpers

  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    get '/-/ide'
  end

  it 'adds CSP headers for code suggestions' do
    expect(find_csp_directive('connect-src')).to include("https://codesuggestions.gitlab.com/")
  end
end
