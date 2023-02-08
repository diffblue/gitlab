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
    subject { entity.as_json }

    shared_examples 'required fields' do
      it 'are present' do
        expect(subject).to include(:merge_request_iid)
        expect(subject).to include(:author)
      end
    end

    context "when user can read merge_request" do
      let(:opts) { { request: request } }

      before do
        project.add_developer(user)
        allow(request).to receive(:current_user).and_return(user)
      end

      it 'contains merge_request_path' do
        expect(subject).to include(:merge_request_path)
      end

      it_behaves_like 'required fields'
    end

    context "when user cannot read merge_request" do
      it_behaves_like 'required fields'
    end
  end
end
