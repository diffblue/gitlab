# frozen_string_literal: true

require 'spec_helper'

RSpec.describe '1_settings' do
  context 'cron jobs' do
    subject(:cron_jobs) { Settings.cron_jobs }

    context 'sync_seat_link_worker cron job' do
      # explicit use of UTC for self-managed instances to ensure job runs after a Customers Portal job
      it 'schedules the job at the correct time' do
        expect(cron_jobs.dig('sync_seat_link_worker', 'cron')).to match(/[1-5]{0,1}[0-9]{1,2} [34] \* \* \* UTC/)
      end
    end
  end
end
