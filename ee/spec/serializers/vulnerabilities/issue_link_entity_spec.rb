# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::IssueLinkEntity, feature_category: :vulnerability_management do
  # rubocop: disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  # rubocop: enable RSpec/FactoryBot/AvoidCreate

  let_it_be(:issue) { build_stubbed(:issue, project: project, author: user) }

  let(:issue_link) { build_stubbed(:vulnerabilities_issue_link, issue: issue) }

  let(:opts) { {} }

  let(:entity) do
    described_class.represent(issue_link, opts)
  end

  describe '#as_json' do
    subject(:serialized_issue_link) { entity.as_json }

    shared_examples 'required fields' do
      it 'are present' do
        expect(serialized_issue_link).to include(:issue_iid)
        expect(serialized_issue_link).to include(:author)
        expect(serialized_issue_link).to include(:created_at)
        expect(serialized_issue_link).to include(:author)
        expect(serialized_issue_link).to include(:link_type)
      end
    end

    context 'when the request is not nil' do
      let(:opts) { { request: request } }

      context 'when the user is available' do
        let(:request) { EntityRequest.new(current_user: user) }

        it_behaves_like 'required fields'

        context 'when the user can not read issue' do
          it 'does not contain issue_url' do
            expect(serialized_issue_link).not_to include(:issue_url)
          end
        end

        context 'when the user can read issue' do
          before do
            project.add_developer(user)
          end

          it 'contains issue_url' do
            expect(serialized_issue_link).to include(:issue_url)
          end
        end
      end

      context 'when the user is not available' do
        let(:request) { EntityRequest.new({}) }

        it_behaves_like 'required fields'

        it 'does not contain issue_url' do
          expect(serialized_issue_link).not_to include(:issue_url)
        end
      end
    end

    context 'when the request is nil' do
      it_behaves_like 'required fields'

      it 'does not contain issue_url' do
        expect(serialized_issue_link).not_to include(:issue_url)
      end
    end
  end
end
