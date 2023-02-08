# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::IssueLink, feature_category: :vulnerability_management do
  describe 'associations and fields' do
    it { is_expected.to belong_to(:vulnerability) }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to have_one(:author).through(:issue).class_name("User") }

    it { is_expected.to define_enum_for(:link_type).with_values(related: 1, created: 2) }

    it 'provides the "related" as default link_type' do
      expect(create(:vulnerabilities_issue_link).link_type).to eq 'related'
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:vulnerability) }
    it { is_expected.to validate_presence_of(:issue) }

    describe 'uniqueness' do
      before do
        create(:vulnerabilities_issue_link)
      end

      it do
        is_expected.to(
          validate_uniqueness_of(:issue_id)
            .scoped_to(:vulnerability_id)
            .with_message('has already been linked to another vulnerability'))
      end
    end

    describe 'only one "created" link allowed per vulnerability' do
      let!(:existing_link) { create(:vulnerabilities_issue_link, :created) }

      subject(:issue_link) do
        build(:vulnerabilities_issue_link, :created, vulnerability: existing_link.vulnerability)
      end

      it do
        is_expected.to(
          validate_uniqueness_of(:vulnerability_id)
            .with_message('already has a "created" issue link'))
      end
    end
  end

  describe 'data consistency constraints' do
    context 'when a link between the same vulnerability and issue already exists' do
      let!(:existing_link) { create(:vulnerabilities_issue_link) }

      it 'raises the uniqueness violation error' do
        expect do
          issue_link = build(
            :vulnerabilities_issue_link,
            issue_id: existing_link.issue_id,
            vulnerability_id: existing_link.vulnerability_id)
          issue_link.save!(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'when there is an existing "created" issue link for vulnerability' do
      let!(:existing_link) { create(:vulnerabilities_issue_link, :created) }

      it 'prevents the creation of a new "created" issue link' do
        expect do
          issue_link = build(:vulnerabilities_issue_link, :created, vulnerability: existing_link.vulnerability)
          issue_link.save!(validate: false)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 'allows the creation of a new "related" issue link' do
        expect do
          issue_link = build(:vulnerabilities_issue_link, :related, vulnerability: existing_link.vulnerability)
          issue_link.save!(validate: false)
        end.not_to raise_error
      end
    end
  end

  describe '.by_link_type' do
    let_it_be(:created_issue_link) { create(:vulnerabilities_issue_link, :created) }
    let_it_be(:related_issue_link) { create(:vulnerabilities_issue_link, :related) }

    subject { described_class.by_link_type(link_type).to_a }

    context 'when the given argument is `nil`' do
      let(:link_type) { nil }

      it { is_expected.to match_array([created_issue_link, related_issue_link]) }
    end

    context 'when the given argument is an uppercase string enum value' do
      let(:link_type) { 'CREATED' }

      it { is_expected.to match_array([created_issue_link]) }
    end

    context 'when the given argument is an uppercase symbol enum value' do
      let(:link_type) { :RELATED }

      it { is_expected.to match_array([related_issue_link]) }
    end
  end

  describe '.for_issue' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:created_issue_link) { create(:vulnerabilities_issue_link, :created, issue: issue) }
    let_it_be(:related_issue_link) { create(:vulnerabilities_issue_link, :related, issue: issue) }

    subject { described_class.for_issue(issue).to_a }

    it { is_expected.to match_array([created_issue_link, related_issue_link]) }
  end
end
