import { GlSprintf, GlLink, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import { GlSingleStat, GlLineChart } from '@gitlab/ui/dist/charts';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useFakeDate } from 'helpers/fake_date';

import RunnerWaitTimes from 'ee/ci/runner/components/runner_wait_times.vue';
import runnerWaitTimesQuery from 'ee/ci/runner/graphql/performance/runner_wait_times.query.graphql';
import runnerWaitTimeHistoryQuery from 'ee/ci/runner/graphql/performance/runner_wait_time_history.query.graphql';
import { I18N_MEDIAN, I18N_P75, I18N_P90, I18N_P99 } from 'ee/ci/runner/constants';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import HelpPopover from '~/vue_shared/components/help_popover.vue';

import { runnersWaitTimes, runnerWaitTimeHistory } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('RunnerActiveList', () => {
  let wrapper;
  let runnerWaitTimesHandler;
  let runnerWaitTimeHistoryHandler;

  const findSingleStats = () => wrapper.findAllComponents(GlSingleStat);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findChart = () => wrapper.findComponent(GlLineChart);

  const getStatData = () =>
    findSingleStats().wrappers.map((w) => [w.props('title'), w.props('value')]);

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerWaitTimes, {
      apolloProvider: createMockApollo([
        [runnerWaitTimesQuery, runnerWaitTimesHandler],
        [runnerWaitTimeHistoryQuery, runnerWaitTimeHistoryHandler],
      ]),
      stubs: { GlSprintf },
    });
  };

  beforeEach(() => {
    runnerWaitTimesHandler = jest.fn().mockResolvedValue(new Promise(() => {}));
    runnerWaitTimeHistoryHandler = jest.fn().mockResolvedValue(new Promise(() => {}));
  });

  describe('When loading data', () => {
    useFakeDate('2023-9-18');

    beforeEach(() => {
      createComponent();
    });

    it('shows loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('requests wait times', () => {
      expect(runnerWaitTimesHandler).toHaveBeenCalledTimes(1);
    });

    it('shows loading area', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('requests wait time history', () => {
      expect(runnerWaitTimeHistoryHandler).toHaveBeenCalledTimes(1);
      expect(runnerWaitTimeHistoryHandler).toHaveBeenCalledWith({
        fromTime: '2023-09-17T21:00:00.000Z',
        toTime: '2023-09-18T00:00:00.000Z',
      });
    });

    it('shows help popover with link', () => {
      expect(findHelpPopover().findComponent(GlLink).exists()).toBe(true);
    });

    it('shows placeholder stats', () => {
      expect(getStatData()).toEqual([
        [I18N_MEDIAN, '-'],
        [I18N_P75, '-'],
        [I18N_P90, '-'],
        [I18N_P99, '-'],
      ]);
    });

    it('shows no chart', () => {
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('When wait times are loaded', () => {
    beforeEach(async () => {
      runnerWaitTimesHandler.mockResolvedValue(runnersWaitTimes);
      runnerWaitTimeHistoryHandler.mockResolvedValue(runnerWaitTimeHistory);

      createComponent();
      await waitForPromises();
    });

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('shows stats', () => {
      expect(getStatData()).toEqual([
        [I18N_P99, '99'],
        [I18N_P90, '90'],
        [I18N_P75, '75'],
        [I18N_MEDIAN, '50'],
      ]);
    });

    it('shows chart', () => {
      const chartData = findChart().props('data');

      expect(chartData).toHaveLength(4); // p99, p95, p90 & p50

      chartData.forEach(({ name, data }) => {
        expect(name).toEqual(expect.any(String));
        expect(data).toHaveLength(2); // 2 sample points
      });
    });
  });
});
