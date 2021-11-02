# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab' do
  subject { Gitlab::Application.config }

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    context 'when the GITLAB_LEGACY_SESSION_STORE env is enabled' do
      before do
        stub_env('GITLAB_LEGACY_SESSION_STORE', true)
      end

      it 'returns the regular cookie without a suffix' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(servers: kind_of(Hash)))

        load_session_store
      end

    end

    context 'when the GITLAB_LEGACY_SESSION_STORE env is not set' do
      before do
        stub_env('GITLAB_LEGACY_SESSION_STORE', nil)
      end

      it 'returns the regular cookie without a suffix' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(redis_store: kind_of(::Redis::Store)))

        load_session_store
      end
    end
  end
end
