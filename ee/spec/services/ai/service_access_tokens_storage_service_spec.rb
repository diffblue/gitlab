# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::ServiceAccessTokensStorageService, :freeze_time, feature_category: :application_performance do
  before do
    create(:service_access_token, :code_suggestions, :expired)
    create(:service_access_token, :code_suggestions, :expired)
    create(:service_access_token, :code_suggestions, :active)
  end

  describe '#execute' do
    shared_examples 'cleans up all tokens' do
      it 'removes all tokens' do
        expect { subject }.to change { Ai::ServiceAccessToken.count }.to(0)
      end

      it 'logs that it cleans up all tokens' do
        expect(Gitlab::AppLogger).to receive(:info)
                                       .with(
                                         message: 'service_access_tokens',
                                         service_token_category: category,
                                         action: 'cleanup_all'
                                       )

        subject
      end
    end

    shared_examples 'cleans up all expired tokens' do
      it 'cleans up all expired tokens' do
        expect { subject }.to change { Ai::ServiceAccessToken.expired.count }.to(0)
      end
    end

    let_it_be(:token) { 'token' }
    let_it_be(:expires_at) { (Time.current + 1.day).to_i }
    let_it_be(:category) { 'code_suggestions' }

    subject { described_class.new(token, expires_at, category).execute }

    context 'when category is not present' do
      let(:category) { nil }

      it { is_expected.to eq(false) }

      it 'does not change Ai::ServiceAccessToken.count' do
        expect { subject }.not_to change { Ai::ServiceAccessToken.count }
      end
    end

    context 'when an invalid category is present' do
      let(:category) { 'hamburgers' }

      it { is_expected.to eq(false) }

      it 'does not change Ai::ServiceAccessToken.count' do
        expect { subject }.not_to change { Ai::ServiceAccessToken.count }
      end
    end

    context 'with valid category' do
      context 'when token and expires_at are present' do
        it 'creates a new token' do
          subject

          service_token = Ai::ServiceAccessToken.last
          expect(service_token.token).to eq(token)
          expect(service_token.category).to eq(category)
          expect(service_token.expires_at.to_i).to eq(expires_at)
        end

        it_behaves_like 'cleans up all expired tokens'

        it 'logs the actions it takes' do
          expect(Gitlab::AppLogger).to receive(:info)
                                         .with(
                                           message: 'service_access_tokens',
                                           service_token_category: category,
                                           action: 'created',
                                           expires_at: Time.at(expires_at, in: '+00:00')
                                         ).ordered
          expect(Gitlab::AppLogger).to receive(:info)
                                         .with(
                                           message: 'service_access_tokens',
                                           service_token_category: category,
                                           action: 'cleanup_expired'
                                         ).ordered

          subject
        end

        context 'when it fails to create a token' do
          let_it_be(:expires_at) { 'not_a_real_date' }

          it 'tracks the error' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(TypeError))

            subject
          end

          it_behaves_like 'cleans up all expired tokens'
        end
      end

      context 'when token is not present' do
        let_it_be(:token) { nil }

        it_behaves_like 'cleans up all tokens'
      end

      context 'when expires_at is not present' do
        let_it_be(:expires_at) { nil }

        it_behaves_like 'cleans up all tokens'
      end
    end
  end
end
