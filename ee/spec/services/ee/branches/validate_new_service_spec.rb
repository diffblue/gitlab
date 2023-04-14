# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Branches::ValidateNewService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  subject(:service) { described_class.new(project) }

  describe '#execute' do
    context 'when no push rules are set' do
      it 'validates the successfully' do
        result = service.execute('no-push-rules')

        expect(result[:status]).to eq(:success)
      end
    end

    context 'when an unrelated push rule is set' do
      let_it_be(:push_rules) { create(:push_rule, project: project) }

      it 'validates successfully' do
        result = service.execute('some-branch')

        expect(result[:status]).to eq(:success)
      end
    end

    context 'when a push rules with branch names are set' do
      let_it_be(:push_rules) { create(:push_rule, project: project, branch_name_regex: '(feature|hotfix)\/*') }

      context 'when branch_name_regex field of push_rule are configured' do
        context 'if the regex is not respected' do
          it 'returns an appropriate error message' do
            result = service.execute('no-match')
            error_message =
              'Cannot create branch. The branch name must match this regular expression: (feature|hotfix)\/*'

            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq(error_message)
          end
        end

        context 'when validations before push rule check failed' do
          it 'returns an error message from previous validations' do
            result = service.execute('-wrong')
            error_message = 'Branch name is invalid'

            expect(result[:status]).to eq(:error)
            expect(result[:message]).to eq(error_message)
          end
        end

        context 'if the regex is respected' do
          it 'validates the successfully' do
            result = service.execute('feature/staging')

            expect(result[:status]).to eq(:success)
          end
        end
      end
    end
  end
end
