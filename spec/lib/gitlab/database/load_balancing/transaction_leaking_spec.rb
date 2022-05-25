# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Load balancer behavior with errors inside a transaction', :redis, :delete do
  let(:model) { ApplicationRecord }
  let(:db_host) { model.connection_pool.db_config.host }

  let(:test_table_name) { '_test_foo' }

  before do
    # Patch in our load balancer config, simply pointing at the test database twice
    allow(Gitlab::Database::LoadBalancing::Configuration).to receive(:for_model) do |base_model|
      Gitlab::Database::LoadBalancing::Configuration.new(base_model, [db_host, db_host])
    end

    Gitlab::Database::LoadBalancing::Setup.new(ApplicationRecord).setup

    model.connection.execute(<<~SQL)
      create table if not exists #{test_table_name} (id serial primary key, value integer)
    SQL
  end

  after do
    model.connection.execute(<<~SQL)
    drop table if exists #{test_table_name}
    SQL
  end

  it 'logs a warning when violating transaction semantics with writes' do
    conn = model.connection

    expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:warn).with(hash_including(event: :transaction_leak))

    conn.transaction do
      expect(conn).to be_transaction_open
      conn.execute("insert into #{test_table_name} (value) VALUES (1)")
      conn.execute("set local idle_in_transaction_session_timeout='100ms'")
      sleep(0.2) # transaction times out

      # This will run into a PG error, which is not raised.
      # Instead, we retry the insert on a fresh connection
      # and hence this violates transaction semantics.
      conn.execute("insert into #{test_table_name} (value) VALUES (2)")
      expect(conn).not_to be_transaction_open
    end
    values = conn.execute("select value from #{test_table_name}").to_a.map { |row| row['value'] }
    expect(values).to contain_exactly(2) # Does not include 1 because the transaction was aborted and leaked
  end
end
