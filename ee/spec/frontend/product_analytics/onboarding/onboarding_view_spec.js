import { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ProductAnalyticsOnboardingView from 'ee/product_analytics/onboarding/onboarding_view.vue';
import ProductAnalyticsOnboardingSetup from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import ProductAnalyticsOnboardingState from 'ee/product_analytics/onboarding/components/onboarding_state.vue';
import OnboardingEmptyState from 'ee/product_analytics/onboarding/components/onboarding_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import { createAlert } from '~/alert';
import {
  STATE_LOADING_INSTANCE,
  STATE_CREATE_INSTANCE,
  STATE_WAITING_FOR_EVENTS,
  FETCH_ERROR_MESSAGE,
} from 'ee/product_analytics/onboarding/constants';
import {
  TEST_JITSU_KEY,
  TEST_COLLECTOR_HOST,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { TEST_PROJECT_FULL_PATH } from '../mock_data';

jest.mock('~/alert');

describe('ProductAnalyticsOnboardingView', () => {
  let wrapper;

  const $router = {
    push: jest.fn(),
  };

  const errorMessage = 'some error';

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(OnboardingEmptyState);
  const findSetupView = () => wrapper.findComponent(ProductAnalyticsOnboardingSetup);
  const findStateComponent = () => wrapper.findComponent(ProductAnalyticsOnboardingState);

  const createWrapper = (listeners = {}) => {
    wrapper = shallowMountExtended(ProductAnalyticsOnboardingView, {
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
        chartEmptyStateIllustrationPath: TEST_HOST,
        collectorHost: TEST_COLLECTOR_HOST,
        jitsuKey: TEST_JITSU_KEY,
      },
      mocks: {
        $router,
      },
      listeners,
    });
  };

  const emitStateChange = async (state) => {
    await findStateComponent().vm.$emit('change', state);
    await nextTick();
  };

  const expectAlertOnError = async ({ finder, captureError, message }) => {
    const error = new Error(errorMessage);

    finder().vm.$emit('error', error);

    await nextTick();

    expect(createAlert).toHaveBeenCalledWith({
      message,
      captureError,
      error,
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when mounted', () => {
    it('shows the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show the empty view', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show the setup view', () => {
      expect(findSetupView().exists()).toBe(false);
    });

    it('creates an onboarding state component', () => {
      expect(findStateComponent().props()).toMatchObject({
        state: '',
        pollState: false,
      });
    });
  });

  describe('create and loading instance', () => {
    it.each([STATE_CREATE_INSTANCE, STATE_LOADING_INSTANCE])(
      'renders the empty state when the state is "%s"',
      async (state) => {
        await emitStateChange(state);

        expect(findEmptyState().props('loadingInstance')).toBe(state === STATE_LOADING_INSTANCE);
      },
    );
  });

  describe('when waiting for events', () => {
    beforeEach(() => {
      return emitStateChange(STATE_WAITING_FOR_EVENTS);
    });

    it('renders the setup view', () => {
      expect(findSetupView().props('isInitialSetup')).toBe(true);
    });
  });

  describe('empty state component events', () => {
    beforeEach(() => {
      return emitStateChange(STATE_CREATE_INSTANCE);
    });

    it(`activates polling on initialized`, async () => {
      findEmptyState().vm.$emit('initialized');

      await nextTick();

      expect(findStateComponent().props('pollState')).toBe(true);
    });

    it('creates an alert on error with the error message', () => {
      expectAlertOnError({ finder: findEmptyState, captureError: true, message: errorMessage });
    });
  });

  describe('state component events', () => {
    it('routes to "index" on complete', async () => {
      findStateComponent().vm.$emit('complete');

      await nextTick();

      expect($router.push).toHaveBeenCalledWith({ name: 'index' });
    });

    it('creates an alert on error with a fixed message', () => {
      expectAlertOnError({
        finder: findStateComponent,
        captureError: false,
        message: FETCH_ERROR_MESSAGE,
      });
    });
  });
});
