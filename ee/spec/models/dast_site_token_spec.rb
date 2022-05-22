# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteToken, type: :model do
  subject { create(:dast_site_token) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:token).is_at_most(255) }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_presence_of(:token) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_uniqueness_of(:url).scoped_to(:project_id) }

    it_behaves_like 'dast url addressable'
  end

  describe '#dast_site' do
    context 'when dast_site exists' do
      it 'finds the associated dast_site' do
        dast_site = create(:dast_site, project_id: subject.project_id, url: subject.url)

        expect(subject.dast_site).to eq(dast_site)
      end
    end

    context 'when dast_site does not exist' do
      it 'returns nil' do
        expect(subject.dast_site).to be_nil
      end
    end
  end
end
