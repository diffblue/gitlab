import {
  runnerWaitTimeQueryData,
  runnerWaitTimeHistoryQueryData,
} from 'ee/ci/runner/runner_performance_utils';

import { I18N_MEDIAN, I18N_P75, I18N_P90, I18N_P99 } from 'ee/ci/runner/constants';

describe('runner_performance_utils', () => {
  describe('runnerWaitTimeQueryData', () => {
    it('empty data returns placeholders', () => {
      expect(runnerWaitTimeQueryData(undefined)).toEqual([
        { key: 'p50', title: I18N_MEDIAN, value: '-' },
        { key: 'p75', title: I18N_P75, value: '-' },
        { key: 'p90', title: I18N_P90, value: '-' },
        { key: 'p99', title: I18N_P99, value: '-' },
      ]);
    });

    it('single stat', () => {
      expect(
        runnerWaitTimeQueryData({
          p50: 50,
          __typename: 'CiJobsDurationStatistics',
        }),
      ).toEqual([{ key: 'p50', title: I18N_MEDIAN, value: '50' }]);
    });

    it.each([
      [null, '-'],
      [0.99, '0.99'],
      [0.991, '0.99'],
      [0.999, '1'],
      [1, '1'],
      [1000, '1,000'],
    ])('single stat, %p formatted as %p', (value, formatted) => {
      expect(
        runnerWaitTimeQueryData({
          p50: value,
          __typename: 'CiJobsDurationStatistics',
        }),
      ).toEqual([{ key: 'p50', title: I18N_MEDIAN, value: formatted }]);
    });

    it('single stat, unknown metric name', () => {
      expect(
        runnerWaitTimeQueryData({
          'unknown metric!': 1000.01,
          __typename: 'CiJobsDurationStatistics',
        }),
      ).toEqual([{ key: 'unknown metric!', title: 'unknown metric!', value: '1,000.01' }]);
    });

    it('multiple stats', () => {
      expect(
        runnerWaitTimeQueryData({
          p50: 50,
          p75: 75,
          p90: 90,
          p99: 99,
          __typename: 'CiJobsDurationStatistics',
        }),
      ).toEqual([
        { key: 'p50', title: I18N_MEDIAN, value: '50' },
        { key: 'p75', title: I18N_P75, value: '75' },
        { key: 'p90', title: I18N_P90, value: '90' },
        { key: 'p99', title: I18N_P99, value: '99' },
      ]);
    });
  });

  describe('runnerWaitTimeHistoryQueryData', () => {
    it('empty data', () => {
      expect(runnerWaitTimeHistoryQueryData(undefined)).toEqual([]);
      expect(runnerWaitTimeHistoryQueryData([])).toEqual([]);
    });

    it('transforms a timeseries with one data point', () => {
      const data = runnerWaitTimeHistoryQueryData([
        {
          time: '2023-09-14T10:00:00Z',
          p99: 99,
          __typename: 'QueueingHistoryTimeSeries',
        },
      ]);

      expect(data).toEqual([
        {
          name: I18N_P99,
          data: [['2023-09-14T10:00:00Z', 99]],
        },
      ]);
    });

    it('transforms a timeseries with one data point, unknown series name', () => {
      const data = runnerWaitTimeHistoryQueryData([
        {
          time: '2023-09-14T10:00:00Z',
          'unknown metric!': 99,
          __typename: 'QueueingHistoryTimeSeries',
        },
      ]);

      expect(data).toEqual([
        {
          name: 'unknown metric!',
          data: [['2023-09-14T10:00:00Z', 99]],
        },
      ]);
    });

    it('3 timeseries with 2 data points', () => {
      const data = runnerWaitTimeHistoryQueryData([
        {
          time: '2023-09-14T10:00:00Z',
          p99: 99,
          p90: 90,
          p50: 50,
          __typename: 'QueueingHistoryTimeSeries',
        },
        {
          time: '2023-09-14T11:00:00Z',
          p99: 98,
          p90: 89,
          p50: 49,
          __typename: 'QueueingHistoryTimeSeries',
        },
      ]);

      expect(data).toEqual([
        {
          name: I18N_P99,
          data: [
            ['2023-09-14T10:00:00Z', 99],
            ['2023-09-14T11:00:00Z', 98],
          ],
        },
        {
          name: I18N_P90,
          data: [
            ['2023-09-14T10:00:00Z', 90],
            ['2023-09-14T11:00:00Z', 89],
          ],
        },
        {
          name: I18N_MEDIAN,
          data: [
            ['2023-09-14T10:00:00Z', 50],
            ['2023-09-14T11:00:00Z', 49],
          ],
        },
      ]);
    });
  });
});
