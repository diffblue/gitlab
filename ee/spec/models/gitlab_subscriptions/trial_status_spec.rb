# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::TrialStatus, feature_category: :acquisition do
  describe '#ends_on' do
    it 'exposes the passed in parameter' do
      expect(described_class.new(0, 1).ends_on).to eq(1)
    end
  end

  describe '#percentage_complete' do
    context 'for the beginning of a trial', :freeze_time do
      specify do
        expect(percentage_complete(0, 30)).to eq(3.33)
      end
    end

    context 'for the middle of a trial' do
      specify do
        travel_to(Date.current.advance(days: 15)) do
          expect(percentage_complete(-15, 15)).to eq(50.0)
        end
      end
    end

    context 'for the end of a trial' do
      specify do
        travel_to(Date.current.advance(days: 30)) do
          expect(percentage_complete(-30, 0)).to eq(100.0)
        end
      end
    end

    context 'with rounding' do
      specify do
        travel_to(Date.current.advance(days: 10)) do
          expect(percentage_complete(-10, 20)).to eq(33.33)
        end
      end
    end

    def percentage_complete(start_delta, end_delta)
      trial_status(start_delta, end_delta).percentage_complete
    end
  end

  describe '#days_remaining' do
    context 'for the beginning of a trial', :freeze_time do
      specify do
        expect(days_remaining(0, 30)).to eq(30)
      end
    end

    context 'for the middle of a trial' do
      specify do
        travel_to(Date.current.advance(days: 15)) do
          expect(days_remaining(-15, 15)).to eq(15)
        end
      end
    end

    context 'for the end of a trial' do
      specify do
        travel_to(Date.current.advance(days: 30)) do
          expect(days_remaining(-30, 0)).to eq(0)
        end
      end
    end

    def days_remaining(start_delta, end_delta)
      trial_status(start_delta, end_delta).days_remaining
    end
  end

  describe '#duration', :freeze_time do
    context 'for default trial length' do
      specify do
        expect(duration(0, 30)).to eq(30)
      end
    end

    context 'for custom trial length' do
      specify do
        expect(duration(-5, 5)).to eq(10)
      end
    end

    def duration(start_delta, end_delta)
      trial_status(start_delta, end_delta).duration
    end
  end

  describe '#days_used' do
    context 'for the beginning of a trial', :freeze_time do
      specify do
        expect(days_used(0, 30)).to eq(1)
      end
    end

    context 'for the middle of a trial' do
      specify do
        travel_to(Date.current.advance(days: 15)) do
          expect(days_used(-15, 15)).to eq(15)
        end
      end
    end

    context 'for the end of a trial' do
      specify do
        travel_to(Date.current.advance(days: 30)) do
          expect(days_used(-30, 0)).to eq(30)
        end
      end
    end

    def days_used(start_delta, end_delta)
      trial_status(start_delta, end_delta).days_used
    end
  end

  def trial_status(start_delta, end_delta)
    described_class.new(Date.current.advance(days: start_delta), Date.current.advance(days: end_delta))
  end
end
