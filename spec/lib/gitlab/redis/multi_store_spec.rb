# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MultiStore do
  using RSpec::Parameterized::TableSyntax

  let(:multi_store) { described_class.new(Gitlab::Redis::Sessions.params.merge(serializer: nil), Gitlab::Redis::SharedState.params.merge(serializer: nil))}
  let(:primary_store) { multi_store.primary_store }
  let(:secondary_store) { multi_store.secondary_store }

  subject { multi_store.send(name, *args) }

  context 'with READ redis commands' do
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:value1) { "redis_value1"}
    let_it_be(:value2) { "redis_value2"}
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:keys) { [key1, key2] }
    let_it_be(:values) { [value1, value2] }
    let_it_be(:svalues) { [value2, value1] }

    where(:case_name, :name, :args, :value, :block) do
      'execute :get command'      | :get      | ref(:key1)  | ref(:value1)  | nil
      'execute :mget command'     | :mget     | ref(:keys)  | ref(:values)  | nil
      'execute :mget with block'  | :mget     | ref(:keys)  | ref(:values)  | ->(value) { value }
      'execute :smembers command' | :smembers | ref(:skey)  | ref(:svalues) | nil
    end

    before(:all) do
      redis_shared_state_cleanup!
      redis_sessions_cleanup!

      Gitlab::Redis::Sessions.with do |redis|
        redis.multi do |multi|
          multi.set(key1, value1)
          multi.set(key2, value2)
          multi.sadd(skey, value1)
          multi.sadd(skey, value2)
        end
      end

      Gitlab::Redis::SharedState.with do |redis|
        redis.multi do |multi|
          multi.set(key1, value1)
          multi.set(key2, value2)
          multi.sadd(skey, value1)
          multi.sadd(skey, value2)
        end
      end
    end

    after(:all) do
      redis_shared_state_cleanup!
      redis_sessions_cleanup!
    end

    RSpec.shared_examples_for 'reads correct value' do |store|
      it 'returns the correct value' do
        if value.is_a?(Array)
          # :smemebers does not guarantee the order it will return the values (unsorted set)
          is_expected.to match_array(value)
        else
          is_expected.to eq(value)
        end
      end
    end

    with_them do
      describe "#{name}" do
        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'with feature flag :use_multi_store enabled' do
          before do
            stub_feature_flags(use_multi_store: true)
          end

          context 'when reading from the primary is successful' do
            it 'returns the correct value' do
              expect(primary_store).to receive(name).with(*args).and_call_original

              subject
            end

            it 'does not execute on the secondary store' do
              expect(secondary_store).not_to receive(name)

              subject
            end

            include_examples 'reads correct value'
          end

          context 'when reading from primary instance is raising an exception' do
            before do
              allow(primary_store).to receive(name).with(*args).and_raise(StandardError)
              allow(Gitlab::ErrorTracking).to receive(:log_exception)
            end

            it 'logs the exception' do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
                hash_including(extra: hash_including(:multi_store_error_message),
                               command_name: name))

              subject
            end

            it 'fallback and execute on secondary instance' do
              expect(secondary_store).to receive(name).with(*args).and_call_original
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(Gitlab::Redis::MultiStore::MultiReadError),
                hash_including(command_name: name))

              subject
            end
          end

          context 'when reading from primary instance return no value' do
            before do
              allow(primary_store).to receive(name).and_return(nil)
            end

            it 'fallback and execute on secondary instance' do
              expect(secondary_store).to receive(name).with(*args).and_call_original

              subject
            end

            it 'logs the fallback' do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(Gitlab::Redis::MultiStore::MultiReadError),
                hash_including(command_name: name))

              subject
            end

            it 'increment metrics' do
              expect(multi_store).to receive(:increment_read_fallback_count).with(name)

              subject
            end
          end

          context 'when the command is executed within pipelined block' do
            subject do
              multi_store.pipelined do
                multi_store.send(name, *args)
              end
            end

            it 'is executed only 1 time on primary instance' do
              expect(primary_store).to receive(name).with(*args).once

              subject
            end
          end

          if params[:block]
            subject do
              multi_store.send(name, *args, &block)
            end

            context 'when block is provided' do
              it 'yields to the block' do
                expect(primary_store).to receive(name).and_yield(value)

                subject
              end

              include_examples 'reads correct value'
            end
          end
        end

        context 'with feature flag :use_multi_store is disabled' do
          before do
            stub_feature_flags(use_multi_store: false)
          end

          it 'execute on the secondary instance' do
            expect(secondary_store).to receive(name).with(*args).and_call_original

            subject
          end

          include_examples 'reads correct value'

          it 'does not execute on the primary store' do
            expect(primary_store).not_to receive(name)

            subject
          end
        end
      end
    end
  end

  context 'with WRITE redis commands', :clean_gitlab_redis_sessions, :clean_gitlab_redis_shared_state do
    let_it_be(:key1) { "redis:{1}:key_a" }
    let_it_be(:key2) { "redis:{1}:key_b" }
    let_it_be(:value1) { "redis_value1"}
    let_it_be(:value2) { "redis_value2"}
    let_it_be(:key1_value1) { [key1, value1] }
    let_it_be(:key1_value2) { [key1, value2] }
    let_it_be(:ttl) { 10 }
    let_it_be(:key1_ttl_value1) { [key1, ttl, value1] }
    let_it_be(:skey) { "redis:set:key" }
    let_it_be(:svalues1) { [value2, value1] }
    let_it_be(:svalues2) { [value1] }
    let_it_be(:skey_value1) { [skey, value1] }
    let_it_be(:skey_value2) { [skey, value2] }

    where(:case_name, :name, :args, :expected_value, :verification_name, :verification_args) do
      'execute :set command'       | :set      | ref(:key1_value1)      | ref(:value1)      | :get      | ref(:key1)
      'execute :setnx command'     | :setnx    | ref(:key1_value2)      | ref(:value1)      | :get      | ref(:key2)
      'execute :setex command'     | :setex    | ref(:key1_ttl_value1)  | ref(:ttl)         | :ttl      | ref(:key1)
      'execute :sadd command'      | :sadd     | ref(:skey_value2)      | ref(:svalues1)    | :smembers | ref(:skey)
      'execute :srem command'      | :srem     | ref(:skey_value1)      | []                | :smembers | ref(:skey)
      'execute :del command'       | :del      | ref(:key2)             | nil               | :get      | ref(:key2)
      'execute :flushdb command'   | :flushdb  | nil                    | 0                 | :dbsize   | nil
    end

    before do
      Gitlab::Redis::Sessions.with do |redis|
        redis.multi do |multi|
          multi.set(key2, value1)
          multi.sadd(skey, value1)
        end
      end

      Gitlab::Redis::SharedState.with do |redis|
        redis.multi do |multi|
          multi.set(key2, value1)
          multi.sadd(skey, value1)
        end
      end
    end

    RSpec.shared_examples_for 'verify that store contains values' do |store|
      it "#{store} redis store contains correct values", :aggregate_errors do
        subject

        redis_store = multi_store.send(store)

        if expected_value.is_a?(Array)
          # :smemebers does not guarantee the order it will return the values
          expect(redis_store.send(verification_name, *verification_args)).to match_array(expected_value)
        else
          expect(redis_store.send(verification_name, *verification_args)).to eq(expected_value)
        end
      end
    end

    with_them do
      describe "#{name}" do
        let(:expected_args) {args || no_args }

        before do
          allow(primary_store).to receive(name).and_call_original
          allow(secondary_store).to receive(name).and_call_original
        end

        context 'with feature flag :use_multi_store enabled' do
          before do
            stub_feature_flags(use_multi_store: true)
          end

          context 'when executing on primary instance is successful' do
            it 'executes on both primary and secondary redis store', :aggregate_errors do
              expect(primary_store).to receive(name).with(*expected_args).and_call_original
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original

              subject
            end

            include_examples 'verify that store contains values', :primary_store
            include_examples 'verify that store contains values', :secondary_store
          end

          context 'when executing on the primary instance is raising an exception' do
            before do
              allow(primary_store).to receive(name).with(*expected_args).and_raise(StandardError)
              allow(Gitlab::ErrorTracking).to receive(:log_exception)
            end

            it 'logs the exception and execute on secondary instance', :aggregate_errors do
              expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(StandardError),
                hash_including(extra: hash_including(:multi_store_error_message), command_name: name))
              expect(secondary_store).to receive(name).with(*expected_args).and_call_original

              subject
            end

            include_examples 'verify that store contains values', :secondary_store
          end

          context 'when the command is executed within pipelined block', :aggregate_errors do
            subject do
              multi_store.pipelined do
                multi_store.send(name, *args)
              end
            end

            it 'is executed only 1 time on each instance' do
              expect(primary_store).to receive(name).with(*expected_args).once
              expect(secondary_store).to receive(name).with(*expected_args).once

              subject
            end

            include_examples 'verify that store contains values', :primary_store
            include_examples 'verify that store contains values', :secondary_store
          end
        end

        context 'with feature flag :use_multi_store is disabled' do
          before do
            stub_feature_flags(use_multi_store: false)
          end

          it 'executes only on the secondary redis store', :aggregate_errors do
            expect(secondary_store).to receive(name).with(*expected_args)
            expect(primary_store).not_to receive(name).with(*expected_args)

            subject
          end

          include_examples 'verify that store contains values', :secondary_store
        end
      end
    end
  end

  context 'with unsupported command', :clean_gitlab_redis_shared_state, :clean_gitlab_redis_sessions do
    let_it_be(:key) { "redis:{1}:key_a" }

    subject do
      multi_store.incr(key)
    end

    it 'executes method missing' do
      expect(multi_store).to receive(:method_missing)

      subject
    end

    it 'logs MethodMissingError' do
      expect(Gitlab::ErrorTracking).to receive(:log_exception).with(an_instance_of(Gitlab::Redis::MultiStore::MethodMissingError),
        hash_including(command_name: :incr))
      subject
    end

    it 'increments method missing counter' do
      expect(multi_store).to receive(:increment_method_missing_count).with(:incr)

      subject
    end

    it 'fallback and executes only on the secondary store', :aggregate_errors do
      expect(secondary_store).to receive(:incr).with(key).and_call_original
      expect(secondary_store).not_to receive(:incr)

      subject

      expect(primary_store.get(key)).to be_nil
      expect(secondary_store.get(key)).to eq('1')
    end
  end
end
