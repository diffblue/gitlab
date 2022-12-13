# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).jitsuKey', feature_category: :product_analytics do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          jitsuKey
        }
      }
    )
  end

  subject do
    GitlabSchema.execute(query, context: { current_user: user }).as_json.dig('data', 'project', 'jitsuKey')
  end

  using RSpec::Parameterized::TableSyntax

  where(:licensed, :enabled, :user_role, :jitsu_key, :output) do
    true  | true  | :developer | 'key' | 'key'
    true  | false | :developer | 'key' | nil
    false | true  | :developer | 'key' | nil
    false | false | :developer | 'key' | nil
    true  | true  | :maintainer | 'key' | 'key'
    true  | false | :maintainer | 'key' | nil
    false | true  | :maintainer | 'key' | nil
    false | false | :maintainer | 'key' | nil
    true  | true  | :owner | 'key' | 'key'
    true  | false | :owner | 'key' | nil
    false | true  | :owner | 'key' | nil
    false | false | :owner | 'key' | nil
    true  | true  | :guest | 'key' | nil
    true  | false | :guest | 'key' | nil
    false | true  | :guest | 'key' | nil
    false | false | :guest | 'key' | nil
  end

  with_them do
    before do
      stub_licensed_features(product_analytics: licensed)
      stub_feature_flags(cube_api_proxy: enabled)
      project.add_role(user, user_role)
      project.project_setting.update!(jitsu_key: jitsu_key)
      project.reload
    end

    it { is_expected.to eq(output) }
  end
end
