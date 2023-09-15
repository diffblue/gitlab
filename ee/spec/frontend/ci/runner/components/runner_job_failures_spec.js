import { GlEmptyState, GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { captureException } from '~/ci/runner/sentry_utils';
import { createAlert } from '~/alert';
import { I18N_FETCH_ERROR } from '~/ci/runner/constants';

import RunnerJobFailures from 'ee/ci/runner/components/runner_job_failures.vue';
import RunnerJobFailure from 'ee/ci/runner/components/runner_job_failure.vue';
import runnerFailedJobsQuery from 'ee/ci/runner/graphql/performance/runner_failed_jobs.graphql';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { runnerFailedJobsData } from '../mock_data';

const mockFailedJobs = runnerFailedJobsData.data.jobs.nodes;

jest.mock('~/alert');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('RunnerJobFailures', () => {
  let wrapper;
  let runnerFailedJobsHandler;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAllRunnerJobFailures = () => wrapper.findAllComponents(RunnerJobFailure);

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, ...options } = {}) => {
    wrapper = mountFn(RunnerJobFailures, {
      apolloProvider: createMockApollo([[runnerFailedJobsQuery, runnerFailedJobsHandler]]),
      propsData: {
        ...props,
      },
      ...options,
    });
  };

  beforeEach(() => {
    runnerFailedJobsHandler = jest.fn().mockResolvedValue(new Promise(() => {}));
  });

  describe('When loading data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows loading skeleton', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('When there are no failures', () => {
    beforeEach(async () => {
      runnerFailedJobsHandler.mockResolvedValue({ data: { jobs: [] } });

      createComponent();

      await waitForPromises();
    });

    it('shows empty state', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findAllRunnerJobFailures()).toHaveLength(0);

      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('When there are failures', () => {
    beforeEach(async () => {
      runnerFailedJobsHandler.mockResolvedValue(runnerFailedJobsData);

      createComponent();

      await waitForPromises();
    });

    it('shows failed jobs', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findAllRunnerJobFailures().at(0).props('job')).toEqual(mockFailedJobs[0]);
      expect(findAllRunnerJobFailures().at(1).props('job')).toEqual(mockFailedJobs[1]);
    });

    it('does not show empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('When there is an error', () => {
    const mockError = new Error('error!');

    beforeEach(async () => {
      runnerFailedJobsHandler.mockRejectedValue(mockError);

      createComponent();
      await waitForPromises();
    });

    it('shows and reports error', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: I18N_FETCH_ERROR });
      expect(captureException).toHaveBeenCalledWith({
        component: 'RunnerJobFailures',
        error: mockError,
      });
    });

    it('shows empty state', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
      expect(findAllRunnerJobFailures()).toHaveLength(0);

      expect(findEmptyState().exists()).toBe(true);
    });
  });
});
