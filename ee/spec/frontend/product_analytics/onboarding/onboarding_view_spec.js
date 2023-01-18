import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import OnboardingEmptyState from 'ee/product_analytics/onboarding/components/onboarding_empty_state.vue';
import initializeProductAnalyticsMutation from 'ee/product_analytics/graphql/mutations/initialize_product_analytics.mutation.graphql';
import getProjectJitsuKeyQuery from 'ee/product_analytics/graphql/mutations/get_project_jitsu_key.query.graphql';
import { hasAnalyticsData } from 'ee/product_analytics/dashboards/data_sources/cube_analytics';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/flash';
import {
  NO_INSTANCE_DATA,
  CUBE_DATA_CHECK_DELAY,
  JITSU_KEY_CHECK_DELAY,
} from 'ee/product_analytics/onboarding/constants';
import { s__ } from '~/locale';
import { createInstanceResponse, getJitsuKeyResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('ee/product_analytics/dashboards/data_sources/cube_analytics', () => ({
  hasAnalyticsData: jest.fn(),
}));
jest.mock('~/flash');

describe('ProductAnalyticsOnboardingView', () => {
  let resolveHasAnalyticsData;
  let rejectHasAnalyticsData;
  let wrapper;

  const fatalError = new Error('GraphQL networkError');
  const apiErrorMsg = 'Product analytics initialization is already complete';
  const jitsuKey = 'valid-jitsu-key';
  const mockCreateInstanceSuccess = jest.fn().mockResolvedValue(createInstanceResponse());
  const mockCreateInstanceLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockCreateInstanceApiError = jest
    .fn()
    .mockResolvedValue(createInstanceResponse([apiErrorMsg]));
  const mockCreateInstanceFatalError = jest.fn().mockRejectedValue(fatalError);
  const mockGetJitsuKeyHasKeySuccess = jest.fn().mockResolvedValue(getJitsuKeyResponse(jitsuKey));
  const mockGetJitsuKeyHasKeySuccessRetry = jest
    .fn()
    .mockResolvedValueOnce(getJitsuKeyResponse(null))
    .mockResolvedValueOnce(getJitsuKeyResponse(jitsuKey));
  const mockGetJitsuKeyError = jest.fn().mockRejectedValue(fatalError);

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(OnboardingEmptyState);
  const findOnboardingSetupView = () => wrapper.findComponent(ProductAnalyticsOnboardingSetup);

  const createWrapper = ({ handlers, status = '' }) => {
    wrapper = shallowMountExtended(ProductAnalyticsOnboardingView, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        status,
      },
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
        projectFullPath: 'group-1/project-1',
        projectId: '1',
        jitsuHost: TEST_HOST,
        jitsuProjectId: '',
      },
    });
  };

  const waitForApolloTimers = async () => {
    jest.advanceTimersByTime(JITSU_KEY_CHECK_DELAY);
    return waitForPromises();
  };

  beforeEach(() => {
    hasAnalyticsData.mockReturnValue(
      new Promise((resolve, reject) => {
        resolveHasAnalyticsData = resolve;
        rejectHasAnalyticsData = reject;
      }),
    );
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when mounted', () => {
    it('shows the loading icon if no instance data', () => {
      createWrapper({ status: NO_INSTANCE_DATA });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('should render the empty state that is not loading', async () => {
      createWrapper({});

      await waitForPromises();

      expect(findEmptyState().props('loading')).toBe(false);
    });

    it('has a polling interval for querying the jitsu key', () => {
      createWrapper({});

      expect(wrapper.vm.$apollo.queries.jitsuKey.options.pollInterval).toBe(JITSU_KEY_CHECK_DELAY);
    });

    it.each`
      view                          | finder             | status              | exists
      ${'loading onboarding setup'} | ${findLoadingIcon} | ${''}               | ${false}
      ${'empty state'}              | ${findEmptyState}  | ${''}               | ${true}
      ${'loading icon'}             | ${findLoadingIcon} | ${NO_INSTANCE_DATA} | ${true}
      ${'empty state'}              | ${findEmptyState}  | ${NO_INSTANCE_DATA} | ${false}
    `('renders the $view view if status is "$status"', async ({ finder, status, exists }) => {
      createWrapper({ status });

      await waitForPromises();

      expect(finder().exists()).toBe(exists);
    });
  });

  describe('when creating an instance', () => {
    it('should show loading while the instance is initializing', async () => {
      createWrapper({
        handlers: [[initializeProductAnalyticsMutation, mockCreateInstanceLoading]],
      });

      await waitForPromises();

      await findEmptyState().vm.$emit('initialize');

      expect(findEmptyState().props('loading')).toBe(true);
    });

    it('should show loading and poll for the jitsu key while it is null', async () => {
      createWrapper({
        handlers: [
          [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
          [getProjectJitsuKeyQuery, mockGetJitsuKeyHasKeySuccessRetry],
        ],
      });

      await waitForPromises();

      findEmptyState().vm.$emit('initialize');

      await nextTick();

      expect(findEmptyState().props('loading')).toBe(true);

      await waitForPromises();

      expect(mockGetJitsuKeyHasKeySuccessRetry.mock.calls).toHaveLength(1);

      await waitForApolloTimers();

      expect(mockGetJitsuKeyHasKeySuccessRetry.mock.calls).toHaveLength(2);
      expect(findOnboardingSetupView().exists()).toBe(true);
    });

    it('should return the jitsu key if creating an instance is successful', async () => {
      createWrapper({
        handlers: [
          [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
          [getProjectJitsuKeyQuery, mockGetJitsuKeyHasKeySuccess],
        ],
      });

      await waitForPromises();

      findEmptyState().vm.$emit('initialize');

      await waitForPromises();

      expect(mockGetJitsuKeyHasKeySuccess).toHaveBeenCalledTimes(1);
      expect(findOnboardingSetupView().exists()).toBe(true);
    });

    it('should show the error if getting the jitsu key throws an error', async () => {
      createWrapper({
        handlers: [
          [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
          [getProjectJitsuKeyQuery, mockGetJitsuKeyError],
        ],
      });

      await waitForPromises();

      findEmptyState().vm.$emit('initialize');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: fatalError.message,
        captureError: true,
        error: fatalError,
      });
    });

    describe('when a create instance error occurs', () => {
      it.each`
        type          | mockError                       | alertError                | captureError
        ${'instance'} | ${mockCreateInstanceFatalError} | ${fatalError}             | ${true}
        ${'api'}      | ${mockCreateInstanceApiError}   | ${new Error(apiErrorMsg)} | ${false}
      `(
        'should create an alert for $type errors',
        async ({ mockError, alertError, captureError }) => {
          createWrapper({ handlers: [[initializeProductAnalyticsMutation, mockError]] });

          await waitForPromises();

          findEmptyState().vm.$emit('initialize');

          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message: alertError.message,
            captureError,
            error: alertError,
          });
        },
      );
    });
  });

  describe(`when "${NO_INSTANCE_DATA}" status`, () => {
    beforeEach(() => {
      createWrapper({ status: NO_INSTANCE_DATA });
    });

    it('polls for onboarding status completion', () => {
      expect(hasAnalyticsData).toHaveBeenCalledTimes(1);
    });

    it('after original request returns, polls again after interval', async () => {
      resolveHasAnalyticsData(false);
      await waitForPromises();

      expect(hasAnalyticsData).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(CUBE_DATA_CHECK_DELAY);

      expect(hasAnalyticsData).toHaveBeenCalledTimes(2);
    });

    describe.each`
      desc                     | actFn                                   | expectedCompleteEmit
      ${'with analytics data'} | ${() => resolveHasAnalyticsData(true)}  | ${[[]]}
      ${'with no data'}        | ${() => resolveHasAnalyticsData(false)} | ${undefined}
    `('$desc', ({ actFn, expectedCompleteEmit }) => {
      beforeEach(async () => {
        actFn();

        await nextTick();
      });

      it(`complete emitted = ${expectedCompleteEmit}`, () => {
        expect(wrapper.emitted('complete')).toEqual(expectedCompleteEmit);
      });

      it('hides loading and shows setup view', () => {
        expect(findLoadingIcon().exists()).toBe(false);
        expect(findOnboardingSetupView().exists()).toBe(true);
      });
    });
  });

  // Cube.js passes errors using a custom error type
  // In these tests we're mocking the output of that type
  // https://github.com/cube-js/cube.js/blob/master/packages/cubejs-client-core/src/RequestError.js
  it('should show the alert and bubble up an error if there is any', async () => {
    const error = { response: { message: 'unknown error' } };

    rejectHasAnalyticsData(error);

    createWrapper({ status: NO_INSTANCE_DATA });

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message: s__(
        'ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.',
      ),
      captureError: true,
      error,
    });

    expect(wrapper.emitted('error')).toBeDefined();
  });
});
