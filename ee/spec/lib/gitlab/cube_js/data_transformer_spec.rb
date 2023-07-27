# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CubeJs::DataTransformer, feature_category: :product_analytics_data_management do
  using RSpec::Parameterized::TableSyntax

  let(:cube_query) do
    Gitlab::Json.parse('{
      "dimensions": [],
      "filters": [
        {
          "member": "SnowplowSessions.startAt",
          "operator": "inDateRange",
          "values": ["2023-01-01", "2023-07-01"]
        }
      ],
      "limit": 100,
      "measures": ["SnowplowSessions.count", "SnowplowSessions.repeatPercent"],
      "timeDimensions": [
        {
          "dimension": "SnowplowSessions.startAt",
          "granularity": "day"
        }
      ],
      "timezone": "UTC"
    }')
  end

  let(:totalled_cube_query) do
    Gitlab::Json.parse('{
      "dimensions": [],
      "filters": [
        {
          "member": "SnowplowTrackedEvents.event",
          "operator": "equals",
          "values": ["page_view"]
        },
        {
          "member": "SnowplowTrackedEvents.derivedTstamp",
          "operator": "inDateRange",
          "values": ["2023-01-01", "2023-07-01"]
        }
      ],
      "limit": 100,
      "measures": ["SnowplowTrackedEvents.pageViewsCount"],
      "timeDimensions": [],
      "timezone": "UTC"
    }')
  end

  let(:cube_data) do
    Gitlab::Json.parse(fixture_file('cube_js/query_with_multiple_measures.json', dir: 'ee'))['results']
  end

  let(:totalled_cube_data) do
    Gitlab::Json.parse(fixture_file('cube_js/query_with_data.json', dir: 'ee'))['results']
  end

  let(:new) do
    described_class.new(query: cube_query, results: cube_data.deep_dup)
  end

  describe '#transform' do
    it 'fills the missing dates for a given date range' do
      transformed_data = new.transform[0]['data']

      expect(transformed_data.count).to eq(182)

      expect(transformed_data[0]['SnowplowSessions.startAt.day']).to eq('2023-05-30T00:00:00.000')
      expect(transformed_data[0]['SnowplowSessions.count']).to eq('1')

      expect(transformed_data[181][:'SnowplowSessions.startAt.day']).to eq('2023-07-01T00:00:00.000')
      expect(transformed_data[181][:'SnowplowSessions.count']).to eq('0')
    end

    context 'when the query is for a totalled measurement' do
      let(:cube_data) { totalled_cube_data }
      let(:cube_query) { totalled_cube_query }

      it 'returns the results without transforming them' do
        expect(new.transform).to eq(totalled_cube_data)
      end
    end

    context 'when not provided all attributes' do
      where(:bad_query, :bad_results) do
        cube_query.except('filters') | cube_data
        cube_query.except('measures') | cube_data
        cube_query | []
      end

      with_them do
        let(:cube_data) { bad_results }
        let(:cube_query) { bad_query }

        it 'returns the results without transforming them' do
          expect(new.transform).to eq(bad_results)
        end
      end
    end

    context 'when the result returns an unsupported granularity' do
      where(:granularity, :base_data) do
        'week' | cube_data
        'month' | cube_data
        'quarter' | cube_data
      end

      with_them do
        let(:cube_data) { apply_granularity_to_data(granularity, base_data) }

        it 'returns the results without transforming them' do
          transformed_data = new.transform

          expect(transformed_data[0]['data'][0]["SnowplowSessions.startAt.#{granularity}"])
            .to eq('2023-05-30T00:00:00.000')
          expect(transformed_data).to eq(cube_data)
          expect(transformed_data[0]['data'].length).to eq(3)
        end
      end
    end
  end

  private

  def apply_granularity_to_data(granularity, current_data)
    current_data[0]['data'].map do |data|
      data["SnowplowSessions.startAt.#{granularity}"] = data['SnowplowSessions.startAt.day']
      data.delete('SnowplowSessions.startAt.day')

      data
    end

    current_data
  end
end
