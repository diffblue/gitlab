# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::PoliciesController, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:index) { group_security_policies_url(group) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    using RSpec::Parameterized::TableSyntax

    where(:feature_flag, :status) do
      true | :ok
      false | :not_found
    end

    subject(:request) { get index, params: { group_id: group.to_param } }

    with_them do
      before do
        stub_feature_flags(group_level_security_policies: feature_flag)
      end

      specify do
        subject

        expect(response).to have_gitlab_http_status(status)
      end
    end
  end
end
