# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ProjectSecurityTraining'] do
  let(:fields) { %i[id name description url logo_url is_enabled is_primary] }

  it { expect(described_class).to have_graphql_fields(fields) }

  describe '#is_primary' do
    let(:training) { create(:security_training, :primary) }
    let(:query) { double('query', schema: GitlabSchema, with_error_handling: true) }
    let(:query_context) { GraphQL::Query::Context.new(query: query, values: {}, object: nil) }
    let(:type_instance) { described_class.authorized_new(training, query_context) }

    subject { type_instance.is_primary }

    context 'when the object is destroyed' do
      before do
        training.destroy!
      end

      it { is_expected.to be(false) }
    end

    context 'when the object is not destroyed' do
      context 'when the object is not primary' do
        let(:training) { create(:security_training) }

        it { is_expected.to be(false) }
      end

      context 'when the object is primary' do
        it { is_expected.to be(true) }
      end
    end
  end
end
