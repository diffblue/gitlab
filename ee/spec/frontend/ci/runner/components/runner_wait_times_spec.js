import { GlSprintf, GlLink, GlLoadingIcon } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import RunnerWaitTimes from 'ee/ci/runner/components/runner_wait_times.vue';
import runnerWaitTimesQuery from 'ee/ci/runner/graphql/performance/runner_wait_times.query.graphql';
import { I18N_MEDIAN, I18N_P75, I18N_P90, I18N_P99 } from 'ee/ci/runner/constants';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import HelpPopover from '~/vue_shared/components/help_popover.vue';

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

const getMockRunnerWaitTimesData = (queuedDuration = {}) => ({
  data: {
    runners: {
      jobsStatistics: {
        queuedDuration: {
          p50: 50,
          p75: 75,
          p90: 90,
          p99: 99,
          __typename: 'CiJobsDurationStatistics',
          ...queuedDuration,
        },
        __typename: 'CiJobsStatistics',
      },
      __typename: 'CiRunnerConnection',
    },
  },
});

Vue.use(VueApollo);

describe('RunnerActiveList', () => {
  let wrapper;
  let runnerWaitTimesHandler;

  const findSingleStats = () => wrapper.findAllComponents(GlSingleStat);
  const findHelpPopover = () => wrapper.findComponent(HelpPopover);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const getStatData = () =>
    findSingleStats().wrappers.map((w) => [w.props('title'), w.props('value')]);

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(RunnerWaitTimes, {
      apolloProvider: createMockApollo([[runnerWaitTimesQuery, runnerWaitTimesHandler]]),
      stubs: { GlSprintf },
    });
  };

  beforeEach(() => {
    runnerWaitTimesHandler = jest.fn().mockResolvedValue(new Promise(() => {}));
  });

  describe('When loading data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('Requests most active runners', () => {
      expect(runnerWaitTimesHandler).toHaveBeenCalledTimes(1);
    });

    it('Shows help popover with link', () => {
      expect(findHelpPopover().findComponent(GlLink).exists()).toBe(true);
    });

    it('shows placeholder data', () => {
      expect(getStatData()).toEqual([
        [I18N_MEDIAN, '-'],
        [I18N_P75, '-'],
        [I18N_P90, '-'],
        [I18N_P99, '-'],
      ]);
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('When wait times are loaded', () => {
    beforeEach(async () => {
      runnerWaitTimesHandler.mockResolvedValue(getMockRunnerWaitTimesData());

      createComponent();
      await waitForPromises();
    });

    it('shows stats', () => {
      expect(getStatData()).toEqual([
        [I18N_MEDIAN, '50'],
        [I18N_P75, '75'],
        [I18N_P90, '90'],
        [I18N_P99, '99'],
      ]);
    });
  });

  describe('When wait times must be formatted', () => {
    it.each([
      [null, '-'],
      [0.99, '0.99'],
      [0.991, '0.99'],
      [0.999, '1'],
      [1, '1'],
      [1000, '1,000'],
    ])('formats %p as %p', async (value, formatted) => {
      runnerWaitTimesHandler.mockResolvedValue(getMockRunnerWaitTimesData({ p50: value }));
      createComponent();
      await waitForPromises();

      expect(getStatData()[0]).toEqual([I18N_MEDIAN, formatted]);
    });
  });
});
