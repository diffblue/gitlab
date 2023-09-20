# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::CreateIterableTriggerService, feature_category: :onboarding do
  let(:params) { { work_email: 'work@email.com', opt_in: true } }

  describe '#execute' do
    context 'when sending iterable call' do
      before do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:generate_iterable)
                                                 .with(params)
                                                 .and_return(response)
      end

      context 'when successful' do
        let(:response) { { success: true } }

        it 'returns success: true' do
          result = subject.execute(params)

          expect(result.success?).to be(true)
        end
      end

      context 'when unsuccessful' do
        let(:response) { { success: false } }

        it 'returns success: false with errors' do
          result = subject.execute(params)

          expect(result.success?).to be(false)
          expect(result.reason).to eq(:submission_failed)
          expect(result.errors).to match(['Submission failed'])
        end
      end
    end

    context 'when iterable call fails with an error message from the client' do
      let(:error_message) { 'some error' }

      it 'returns an error' do
        response = Net::HTTPUnprocessableEntity.new(1.0, '422', 'Error')

        gitlab_http_response = instance_double(
          HTTParty::Response,
          code: response.code,
          parsed_response: { errors: error_message }.stringify_keys,
          response: response,
          body: {}
        )

        # going deeper than usual here to verify the API doesn't change and break
        # this area that relies on symbols for `error`
        allow(Gitlab::HTTP).to receive(:post).and_return(gitlab_http_response)
        result = subject.execute(params)

        expect(result.success?).to be(false)
        expect(result.reason).to eq(:submission_failed)
        expect(result.errors).to match([error_message])
      end
    end
  end
end
