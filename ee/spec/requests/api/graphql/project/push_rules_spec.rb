# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).pushRules', feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: user.namespace) }

  subject(:push_rules_response) do
    post_graphql(
      graphql_query_for(
        :project, { full_path: project.full_path }, "pushRules { #{all_graphql_fields_for('PushRules')} }"
      ),
      current_user: user
    )

    graphql_dig_at(graphql_data, 'project', 'pushRules')
  end

  it 'returns nil when push_rules license is false' do
    create(:push_rule, project: project)
    stub_licensed_features(push_rules: false)

    expect(push_rules_response).to be_nil
  end

  describe 'pushRules.rejectUnsignedCommits' do
    where(:field_value, :license_value, :expected) do
      true | true | true
      true | false | false
      false | true | false
      false | false | false
    end

    with_them do
      before do
        create(:push_rule, project: project, reject_unsigned_commits: field_value)
        stub_licensed_features(reject_unsigned_commits: license_value)
      end

      it "returns" do
        expect(push_rules_response).to eq("rejectUnsignedCommits" => expected)
      end
    end
  end
end
