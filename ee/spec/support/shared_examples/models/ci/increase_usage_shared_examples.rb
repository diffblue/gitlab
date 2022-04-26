# frozen_string_literal: true

RSpec.shared_examples_for 'CI minutes increase usage' do
  subject { current_usage.increase_usage(increments) }

  let(:increments) { { amount_used: amount } }

  context 'when amount is greater than 0' do
    let(:amount) { 10.5 }

    it 'updates the current month usage' do
      subject

      expect(current_usage.reload.amount_used).to eq(110.5)
    end
  end

  context 'when amount is less or equal to 0' do
    let(:amount) { -2.0 }

    it 'does not update the current month usage' do
      subject

      expect(current_usage.reload.amount_used).to eq(100.0)
    end
  end

  context 'when shared_runners_duration is incremented' do
    let(:increments) { { amount_used: amount, shared_runners_duration: duration } }
    let(:amount) { 10.5 }

    context 'when duration is positive' do
      let(:duration) { 10 }

      it 'updates the duration and amount used' do
        subject

        expect(current_usage.reload.amount_used).to eq(110.5)
        expect(current_usage.shared_runners_duration).to eq(10)
      end

      context 'when amount_used is zero' do
        let(:amount) { 0 }

        it 'updates only the duration' do
          subject

          expect(current_usage.reload.amount_used).to eq(100.0)
          expect(current_usage.shared_runners_duration).to eq(10)
        end
      end
    end

    context 'when duration is zero' do
      let(:duration) { 0 }

      it 'updates only the amount used' do
        subject

        expect(current_usage.reload.amount_used).to eq(110.5)
        expect(current_usage.shared_runners_duration).to eq(0)
      end

      context 'when amount_used is zero' do
        let(:amount) { 0 }

        it 'does not perform updates' do
          subject

          expect(current_usage.reload.amount_used).to eq(100.0)
          expect(current_usage.shared_runners_duration).to eq(0)
        end
      end
    end
  end
end
