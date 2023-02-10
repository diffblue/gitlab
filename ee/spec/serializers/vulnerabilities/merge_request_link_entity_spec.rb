# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::MergeRequestLinkEntity, feature_category: :vulnerability_management do
  # rubocop: disable RSpec/FactoryBot/AvoidCreate
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  # rubocop: enable RSpec/FactoryBot/AvoidCreate

  let_it_be(:merge_request) { build_stubbed(:merge_request, source_project: project, author: user) }

  let(:merge_request_link) { build_stubbed(:vulnerabilities_merge_request_link, merge_request: merge_request) }

  let(:opts) { {} }
  let(:request) { double(:request) } # rubocop: disable RSpec/VerifiedDoubles

  let(:entity) do
    described_class.represent(merge_request_link, opts)
  end

  describe '#as_json' do
    subject(:serialized_merge_request_link) { entity.as_json }

    shared_examples 'required fields' do
      it 'are present' do
        expect(serialized_merge_request_link).to include(:merge_request_iid)
        expect(serialized_merge_request_link).to include(:author)
      end
    end

    context 'when the request is not nil' do
      let(:opts) { { request: request } }

      context 'when the user is available' do
        let(:request) { EntityRequest.new(current_user: user) }

        it_behaves_like 'required fields'

        context 'when the user can not read MR' do
          it 'does not contain merge_request_path' do
            expect(serialized_merge_request_link).not_to include(:merge_request_path)
          end
        end

        context 'when the user can read MR' do
          before do
            project.add_developer(user)
          end

          it 'contains merge_request_path' do
            expect(serialized_merge_request_link).to include(:merge_request_path)
          end
        end
      end

      context 'when the user is not available' do
        let(:request) { EntityRequest.new({}) }

        it_behaves_like 'required fields'

        it 'does not contain merge_request_path' do
          expect(serialized_merge_request_link).not_to include(:merge_request_path)
        end
      end
    end

    context 'when the request is nil' do
      it_behaves_like 'required fields'

      it 'does not contain merge_request_path' do
        expect(serialized_merge_request_link).not_to include(:merge_request_path)
      end
    end
  end
end
