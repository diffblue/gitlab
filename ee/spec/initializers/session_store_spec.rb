# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Session initializer for GitLab EE' do
  subject { Gitlab::Application.config }

  let(:load_session_store) do
    load Rails.root.join('config/initializers/session_store.rb')
  end

  describe 'config#session_store' do
    shared_examples 'normal session cookie' do
      it 'returns the regular cookie without a suffix' do
        expect(subject).to receive(:session_store).with(:redis_store, a_hash_including(key: '_gitlab_session'))

        load_session_store
      end
    end

    context 'no database connection' do
      before do
        allow(Gitlab::Geo).to receive(:connected?).and_return(false)
      end

      it_behaves_like 'normal session cookie'
    end

    context 'Geo is disabled' do
      before do
        allow(Gitlab::Geo).to receive(:enabled?).and_return(false)
      end

      it_behaves_like 'normal session cookie'
    end

    context 'current node is a Geo primary' do
      before do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(false)
      end

      it_behaves_like 'normal session cookie'
    end

    context 'current node is a Geo secondary' do
      before do
        allow(Gitlab::Geo).to receive(:secondary?).and_return(true)
      end

      it 'returns a geo specific cookie' do
        expect(subject).to receive(:session_store).with(
          :redis_store,
          a_hash_including(key: /_gitlab_session_geo_[0-9a-f]{64}/)
        )

        load_session_store
      end
    end
  end
end
