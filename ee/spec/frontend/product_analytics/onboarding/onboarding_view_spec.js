import VueApollo from 'vue-apollo';
import Vue from 'vue';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import OnboardingEmptyState from 'ee/product_analytics/onboarding/components/onboarding_empty_state.vue';
import initializeProductAnalyticsMutation from 'ee/product_analytics/graphql/mutations/initialize_product_analytics.mutation.graphql';
import getProjectJitsuKeyQuery from 'ee/product_analytics/graphql/mutations/get_project_jitsu_key.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { createAlert } from '~/flash';
import { JITSU_KEY_CHECK_DELAY } from 'ee/product_analytics/onboarding/constants';
import { createInstanceResponse, getJitsuKeyResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/flash');

describe('ProductAnalyticsOnboardingView', () => {
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

  const findEmptyState = () => wrapper.findComponent(OnboardingEmptyState);

  const createWrapper = (handlers) => {
    wrapper = shallowMountExtended(ProductAnalyticsOnboardingView, {
      apolloProvider: createMockApollo(handlers),
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
        projectFullPath: 'group-1/project-1',
      },
    });
  };

  const waitForApolloTimers = async () => {
    jest.advanceTimersByTime(JITSU_KEY_CHECK_DELAY);
    return waitForPromises();
  };

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the empty state that is not loading', () => {
      expect(findEmptyState().props('loading')).toBe(false);
    });

    it('has a polling interval for querying the jitsu key', () => {
      expect(wrapper.vm.$apollo.queries.jitsuKey.options.pollInterval).toBe(JITSU_KEY_CHECK_DELAY);
    });
  });

  describe('when creating an instance', () => {
    it('should show loading while the instance is initializing', async () => {
      createWrapper([[initializeProductAnalyticsMutation, mockCreateInstanceLoading]]);

      await findEmptyState().vm.$emit('initialize');

      expect(findEmptyState().props('loading')).toBe(true);
    });

    it('should show loading and poll for the jitsu key while it is null', async () => {
      createWrapper([
        [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
        [getProjectJitsuKeyQuery, mockGetJitsuKeyHasKeySuccessRetry],
      ]);

      findEmptyState().vm.$emit('initialize');

      await waitForPromises();

      expect(mockGetJitsuKeyHasKeySuccessRetry.mock.calls).toHaveLength(1);
      expect(findEmptyState().props('loading')).toBe(true);

      await waitForApolloTimers();

      expect(mockGetJitsuKeyHasKeySuccessRetry.mock.calls).toHaveLength(2);
      expect(findEmptyState().props('loading')).toBe(false);
    });

    it('should return the jitsu key if creating an instance is successful', async () => {
      createWrapper([
        [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
        [getProjectJitsuKeyQuery, mockGetJitsuKeyHasKeySuccess],
      ]);

      findEmptyState().vm.$emit('initialize');

      await waitForPromises();

      expect(mockGetJitsuKeyHasKeySuccess).toHaveBeenCalledTimes(1);
      expect(findEmptyState().props('loading')).toBe(false);
    });

    it('should show the error if getting the jitsu key throws an error', async () => {
      createWrapper([
        [initializeProductAnalyticsMutation, mockCreateInstanceSuccess],
        [getProjectJitsuKeyQuery, mockGetJitsuKeyError],
      ]);

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
          createWrapper([[initializeProductAnalyticsMutation, mockError]]);

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
});
