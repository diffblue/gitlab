# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableResourceLink, type: :model do
  let_it_be(:issuable_resource_link) { create(:issuable_resource_link) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:issue) }
    it { is_expected.to validate_presence_of(:link) }
    it { is_expected.to validate_length_of(:link).is_at_most(2200) }
    it { is_expected.to validate_length_of(:link_text).is_at_most(255) }

    context 'when link is invalid' do
      let(:issuable_resource_link) { build(:issuable_resource_link, link: 'some-invalid-url') }

      it 'will be invalid' do
        expect(issuable_resource_link).to be_invalid
      end
    end
  end

  describe 'link protocols' do
    using RSpec::Parameterized::TableSyntax

    let(:issuable_resource_link) { build(:issuable_resource_link) }

    where(:protocol, :result) do
      'http'  | be_valid
      'https' | be_valid
      'ftp'   | be_invalid
    end

    with_them do
      specify do
        issuable_resource_link.link = protocol + '://assets.com/download'
        expect(issuable_resource_link).to result
      end
    end
  end

  describe 'enums' do
    let(:link_type_values) do
      { general: 0, zoom: 1, slack: 2 }
    end

    it { is_expected.to define_enum_for(:link_type).with_values(link_type_values) }
  end
end
