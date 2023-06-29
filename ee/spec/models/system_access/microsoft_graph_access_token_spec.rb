# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemAccess::MicrosoftGraphAccessToken, feature_category: :system_access do
  it do
    is_expected
      .to belong_to(:system_access_microsoft_application)
            .inverse_of(:system_access_microsoft_graph_access_token)
  end

  describe 'validations' do
    let_it_be(:graph_access_token) { create(:system_access_microsoft_graph_access_token) }

    it { is_expected.to validate_presence_of(:system_access_microsoft_application_id) }
    it { is_expected.to validate_presence_of(:expires_in) }
    it { is_expected.to validate_numericality_of(:expires_in).is_greater_than_or_equal_to(0) }
  end

  it 'has a bidirectional relationship' do
    application = create(:system_access_microsoft_application)
    token_obj = create(:system_access_microsoft_graph_access_token, system_access_microsoft_application: application)

    expect(token_obj.system_access_microsoft_application).to eq(application)
    expect(token_obj.system_access_microsoft_application.system_access_microsoft_graph_access_token).to eq(token_obj)
  end
end
