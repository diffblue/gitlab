# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Set project compliance framework', feature_category: :compliance_management do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:framework) { create(:compliance_framework, namespace: namespace) }
  let_it_be(:current_user) { create(:user) }

  before do
    namespace.add_owner(current_user)
  end

  let(:variables) { { project_id: GitlabSchema.id_from_object(project).to_s, compliance_framework_id: GitlabSchema.id_from_object(framework).to_s } }

  let(:mutation) do
    graphql_mutation(:project_set_compliance_framework, variables) do
      <<~QL
        project {
          complianceFrameworks {
            nodes {
              name
            }
          }
        }
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:project_set_compliance_framework)
  end

  describe '#resolve' do
    context 'when feature is not available' do
      before do
        stub_licensed_features(compliance_framework: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
                      errors: ['The resource that you are attempting to access does not exist '\
                               'or you don\'t have permission to perform this action']
    end

    context 'when feature is available' do
      before do
        stub_licensed_features(compliance_framework: true)
      end

      it_behaves_like 'a working GraphQL mutation'
    end
  end
end
