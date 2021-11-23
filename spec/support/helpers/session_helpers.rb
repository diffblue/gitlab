# frozen_string_literal: true

module SessionHelpers
  def expect_single_session_with_authenticated_ttl(redis_store_class)
    expect_single_session_with_expiration(redis_store_class, Settings.gitlab['session_expire_delay'] * 60)
  end

  def expect_single_session_with_short_ttl(redis_store_class)
    expect_single_session_with_expiration(redis_store_class, Settings.gitlab['unauthenticated_session_expire_delay'])
  end

  def expect_single_session_with_expiration(redis_store_class, expiration)
    session_keys = get_session_keys(redis_store_class)

    expect(session_keys.size).to eq(1)
    expect(get_ttl(redis_store_class, session_keys.first)).to be_within(5).of(expiration)
  end

  def get_session_keys(redis_store_class)
    redis_store_class.with { |redis| redis.scan_each(match: 'session:gitlab:*').to_a }
  end

  def get_ttl(redis_store_class, key)
    redis_store_class.with { |redis| redis.ttl(key) }
  end
end
