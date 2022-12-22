# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::ExternalIssueLink, feature_category: :vulnerability_management do
  describe 'associations and fields' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to define_enum_for(:link_type).with_values(created: 1) }

    it 'provides the "created" as default link_type' do
      expect(create(:vulnerabilities_external_issue_link).link_type).to eq 'created'
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:vulnerability) }
    it { is_expected.to validate_presence_of(:external_issue_key) }
    it { is_expected.to validate_presence_of(:external_project_key) }
    it { is_expected.to validate_presence_of(:external_type) }

    describe 'uniqueness' do
      before do
        create(:vulnerabilities_external_issue_link)
      end

      it do
        is_expected.to(
          validate_uniqueness_of(:external_issue_key)
            .scoped_to([:vulnerability_id, :external_type, :external_project_key])
            .with_message('has already been linked to another vulnerability'))
      end
    end

    describe 'only one "created" link allowed per vulnerability' do
      let!(:existing_link) { create(:vulnerabilities_external_issue_link, :created) }

      subject(:issue_link) do
        build(:vulnerabilities_external_issue_link, :created, vulnerability: existing_link.vulnerability)
      end

      it do
        is_expected.to(
          validate_uniqueness_of(:vulnerability_id)
            .with_message('already has a "created" issue link'))
      end
    end
  end

  describe 'created_for_vulnerability' do
    let_it_be(:external_links) { create_list(:vulnerabilities_external_issue_link, 2, :created) }

    it 'gets external issue links for the specified vulnerability' do
      expect(described_class.created_for_vulnerability(external_links.first.vulnerability).take).to eq(external_links.first)
    end
  end
end
