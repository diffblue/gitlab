# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BroadcastMessage do
  subject { build(:broadcast_message) }

  describe '.current', :use_clean_rails_memory_store_caching do
    context 'without Geo' do
      it 'caches the output of the query for two weeks' do
        expect(Gitlab::Geo).to receive(:enabled?).and_return(false).twice

        create(:broadcast_message)

        expect(described_class).to receive(:current_and_future_messages).and_call_original.twice

        described_class.current

        travel_to(3.weeks.from_now) do
          described_class.current
        end
      end
    end

    context 'with Geo' do
      context 'on the primary' do
        it 'caches the output of the query for two weeks' do
          expect(Gitlab::Geo).to receive(:enabled?).and_return(false).twice

          create(:broadcast_message)

          expect(described_class).to receive(:current_and_future_messages).and_call_original.twice

          described_class.current

          travel_to(3.weeks.from_now) do
            described_class.current
          end
        end
      end

      context 'on a secondary' do
        it 'caches the output for a short time' do
          expect(Gitlab::Geo).to receive(:secondary?).and_return(true).exactly(3).times

          create(:broadcast_message)

          expect(described_class).to receive(:where).and_call_original.once

          described_class.current

          travel_to(20.seconds.from_now) do
            described_class.current
          end

          expect(described_class).to receive(:where).and_call_original.once

          travel_to(40.seconds.from_now) do
            described_class.current
          end
        end
      end
    end
  end
end
