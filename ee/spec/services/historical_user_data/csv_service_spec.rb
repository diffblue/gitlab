# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HistoricalUserData::CsvService, feature_category: :user_management do
  subject(:csv) { CSV.parse(csv_service.generate) }

  let_it_be(:csv_service) { described_class.new(HistoricalData.all) }

  let_it_be(:datetime) { DateTime.parse('2020-09-04 10:00:00') }
  let_it_be(:license_email) { 'data@example.com' }
  let_it_be(:license_company) { 'Widgets Inc.' }
  let_it_be(:license_start_date) { datetime.to_date - 10.months }
  let_it_be(:license_end_date) { datetime.to_date + 2.months }

  let_it_be(:current_license) do
    create_current_license(
      licensee: { 'Name' => 'Test', 'Email' => license_email, 'Company' => license_company },
      starts_at: license_start_date,
      expires_at: license_end_date
    )
  end

  around do |example|
    travel_to(datetime) { example.run }
  end

  context 'License Information Header' do
    context 'License Key' do
      it 'shows the header title' do
        expect(csv[0][0]).to eq('License Key')
      end

      it 'shows the license key' do
        license = create(:license, data: current_license.data.gsub("\n", "\r\n"))

        allow(License).to receive(:current).and_return(license)

        expect(license.data).not_to eq(license.normalized_data)
        expect(csv[0][1]).to eq(license.normalized_data)
      end
    end

    context 'Email' do
      it 'shows the header title' do
        expect(csv[1][0]).to eq('Email')
      end

      it 'shows the license email' do
        expect(csv[1][1]).to eq(license_email)
      end
    end

    context 'License Start Date' do
      it 'shows the header title' do
        expect(csv[2][0]).to eq('License Start Date')
      end

      it 'shows the license start date' do
        expect(csv[2][1]).to eq(license_start_date.to_fs(:csv))
      end
    end

    context 'License End Date' do
      it 'shows the header title' do
        expect(csv[3][0]).to eq('License End Date')
      end

      it 'shows the license end date' do
        expect(csv[3][1]).to eq(license_end_date.to_fs(:csv))
      end
    end

    context 'Company' do
      it 'shows the header title' do
        expect(csv[4][0]).to eq('Company')
      end

      it 'shows the license company' do
        expect(csv[4][1]).to eq(license_company)
      end
    end

    context 'Generated At' do
      it 'shows the header title' do
        expect(csv[5][0]).to eq('Generated At')
      end

      it 'shows the CSV generation time' do
        expect(csv[5][1]).to eq(datetime.utc.to_fs(:csv))
      end
    end
  end

  context 'Empty Row' do
    it 'adds an empty row between the License Information Header and the User Count Table' do
      expect(csv[6][0]).to eq('')
      expect(csv[6][1]).to eq('')
    end
  end

  context 'User Count Table' do
    let_it_be(:historical_datum) do
      create(:historical_data, recorded_at: license_start_date, active_user_count: 1)
    end

    let_it_be(:historical_datum2) do
      create(:historical_data, recorded_at: license_start_date + 1.day, active_user_count: 2)
    end

    it 'shows the header for the user counts table' do
      expect(csv[7]).to contain_exactly('Date', 'Billable User Count')
    end

    it 'includes proper values for each column type', :aggregate_failures do
      expect(csv[8]).to contain_exactly(
        historical_datum.recorded_at.utc.to_fs(:csv),
        historical_datum.active_user_count.to_s
      )
      expect(csv[9]).to contain_exactly(
        historical_datum2.recorded_at.utc.to_fs(:csv),
        historical_datum2.active_user_count.to_s
      )
    end
  end
end
