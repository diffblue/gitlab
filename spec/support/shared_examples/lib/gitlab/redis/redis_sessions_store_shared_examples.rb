# frozen_string_literal: true

RSpec.shared_examples 'redis sessions store' do |example|
  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is true', :clean_gitlab_redis_sessions do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'true')
    end

    it_behaves_like example do
      let(:redis_store_class) { Gitlab::Redis::Sessions }
    end
  end

  context 'when ENV[GITLAB_USE_REDIS_SESSIONS_STORE] is false', :clean_gitlab_redis_shared_state do
    before do
      stub_env('GITLAB_USE_REDIS_SESSIONS_STORE', 'false')
    end

    it_behaves_like example do
      let(:redis_store_class) { Gitlab::Redis::SharedState }
    end
  end
end
