# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::AiAssist do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_user) { create(:user) }
  let(:current_user) { nil }

  let_it_be(:allowed_group) do
    group = create(:group)
    group.add_owner(group_user)
    group
  end

  describe 'GET /ml/ai-assist user_is_allowed' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_licensed_features(ai_assist: license_flag)
      stub_feature_flags(ai_assist_flag: feature_flag)
    end

    subject { get api('/ml/ai-assist', current_user) }

    context 'when user not logged in' do
      let(:current_user) { nil }

      where(:feature_flag, :license_flag, :result) do
        false | false | :unauthorized
        true | false | :unauthorized
        false | true | :unauthorized
        true | true | :unauthorized
      end

      with_them do
        it 'returns unauthorized' do
          subject
          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in' do
      let(:current_user) { user }

      where(:feature_flag, :license_flag, :result) do
        false | false | :not_found
        true | false | :not_found
        false | true | :not_found
        true | true | :not_found
      end

      with_them do
        it 'returns not found' do
          subject
          expect(response).to have_gitlab_http_status(result)
        end
      end
    end

    context 'when user is logged in and in group' do
      let(:current_user) { group_user }

      where(:feature_flag, :license_flag, :result) do
        false | false | :not_found
        true | false | :not_found
        false | true | :not_found
        true | true | :ok
      end

      with_them do
        it 'returns not found except when both flags true' do
          subject
          expect(response).to have_gitlab_http_status(result)
        end
      end
    end
  end
end
