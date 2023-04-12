# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExecuteMethodService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:resource) { build_stubbed(:issue) }
  let(:options) { {} }

  subject { described_class.new(user, resource, method, options).execute }

  describe '#execute' do
    context 'with a valid method' do
      let(:method) { :summarize_comments }

      it 'calls the correct service' do
        expect_next_instance_of(Llm::GenerateSummaryService, user, resource, options) do |instance|
          allow(instance).to receive(:execute)
        end

        subject
      end
    end

    context 'with an invalid method' do
      let(:method) { :invalid_method }

      it { is_expected.to be_error.and have_attributes(message: eq('Unknown method')) }
    end
  end
end
