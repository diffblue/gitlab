# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['AiMessageType'], feature_category: :not_owned do # rubocop:disable RSpec/InvalidFeatureCategory
  include GraphqlHelpers

  it { expect(described_class.graphql_name).to eq('AiMessageType') }

  it 'has the expected fields' do
    expected_fields = %w[id role content errors is_fetching]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'field values' do
    let_it_be(:project) { create(:project) }
    let_it_be(:message) { create(:message, project: project, user: project.owner, async_errors: ['my_error']) }

    let(:current_user) { project.owner }

    subject { resolve_field(field_name, message, current_user: current_user) }

    describe 'errors' do
      let(:field_name) { :errors }

      it { is_expected.to eq(message.async_errors) }
    end

    describe 'is_fetching' do
      let(:field_name) { :is_fetching }

      it { is_expected.to eq(message.fetching?) }
    end
  end
end
