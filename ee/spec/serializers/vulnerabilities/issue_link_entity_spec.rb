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
  let(:request) { double(:request) } # rubocop: disable RSpec/VerifiedDoubles

  let(:entity) do
    described_class.represent(issue_link, opts)
  end

  describe '#as_json' do
    subject { entity.as_json }

    shared_examples 'required fields' do
      it 'are present' do
        expect(subject).to include(:issue_iid)
        expect(subject).to include(:author)
        expect(subject).to include(:created_at)
        expect(subject).to include(:author)
        expect(subject).to include(:link_type)
      end
    end

    context "when user can read issue" do
      let(:opts) { { request: request } }

      before do
        project.add_developer(user)
        allow(request).to receive(:current_user).and_return(user)
      end

      it 'contains issue_url' do
        expect(subject).to include(:issue_url)
      end

      it_behaves_like 'required fields'
    end

    context "when user cannot read issue" do
      it_behaves_like 'required fields'
    end
  end
end
