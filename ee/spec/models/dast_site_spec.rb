# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSite, type: :model do
  let_it_be(:project) { create(:project) }

  subject { create(:dast_site, project: project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:dast_site_validation) }
    it { is_expected.to have_many(:dast_site_profiles) }
  end

  describe 'validations' do
    it { is_expected.to be_valid }
    it { is_expected.to validate_length_of(:url).is_at_most(255) }
    it { is_expected.to validate_uniqueness_of(:url).scoped_to(:project_id) }
    it { is_expected.to validate_presence_of(:project_id) }

    it_behaves_like 'dast url addressable'

    context 'when the project_id and dast_site_token.project_id do not match' do
      let(:project) { create(:project) }
      let(:dast_site_validation) { create(:dast_site_validation) }

      subject { build(:dast_site, project: project, dast_site_validation: dast_site_validation) }

      it 'is not valid' do
        aggregate_failures do
          expect(subject.valid?).to eq(false)
          expect(subject.errors.full_messages).to include('Project does not match dast_site_validation.project')
        end
      end
    end
  end

  describe 'callbacks' do
    context 'when there is a related site token' do
      let_it_be(:dast_site) { create(:dast_site, project: project) }
      let_it_be(:dast_site_token) { create(:dast_site_token, project: dast_site.project, url: dast_site.url) }
      let_it_be(:dast_site_validations) { create_list(:dast_site_validation, 5, dast_site_token: dast_site_token) }

      it 'ensures it and associated site validations cleaned up on destroy' do
        expect { dast_site.destroy! }.to change { DastSiteToken.count }.from(1).to(0).and change { DastSiteValidation.count }.from(5).to(0)
      end
    end
  end
end
