# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Security::PoliciesController, type: :request do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:edit) { edit_group_security_policy_url(group, id: 'temp') }
  let_it_be(:index) { group_security_policies_url(group) }
  let_it_be(:new) { new_group_security_policy_url(group) }

  before do
    sign_in(user)
  end

  describe 'GET #edit' do
    using RSpec::Parameterized::TableSyntax

    where(:feature_flag, :status) do
      true | :ok
      false | :not_found
    end

    subject(:request) { get edit }

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

  describe 'GET #new' do
    using RSpec::Parameterized::TableSyntax

    where(:feature_flag, :status) do
      true | :ok
      false | :not_found
    end

    subject(:request) { get new }

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
