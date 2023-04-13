# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Llm::ExecuteMethodService, feature_category: :no_category do # rubocop: disable RSpec/InvalidFeatureCategory
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:issue) { build_stubbed(:issue) }

  let(:method) { :summarize_comments }
  let(:resource) { nil }
  let(:options) { {} }

  subject { described_class.new(user, resource, method, options).execute }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    context 'with a valid method' do
      where(:method, :resource, :service_class) do
        :summarize_comments | issue | Llm::GenerateSummaryService
        :explain_code | build_stubbed(:project) | Llm::ExplainCodeService
      end

      with_them do
        it 'calls the correct service' do
          expect_next_instance_of(service_class, user, resource, options) do |instance|
            allow(instance)
              .to receive(:execute)
              .and_return(instance_double(ServiceResponse, success?: true, error?: false, payload: nil))
          end

          expect(subject).to be_success
        end
      end
    end

    context 'when service returns an error' do
      it 'returns an error' do
        expect_next_instance_of(Llm::GenerateSummaryService, user, resource, options) do |instance|
          allow(instance)
            .to receive(:execute)
            .and_return(instance_double(ServiceResponse, success?: false, error?: true, message: 'failed'))
        end

        expect(subject).to be_error.and have_attributes(message: eq('failed'))
      end
    end

    context 'with an invalid method' do
      let(:method) { :invalid_method }

      it { is_expected.to be_error.and have_attributes(message: eq('Unknown method')) }
    end
  end
end
