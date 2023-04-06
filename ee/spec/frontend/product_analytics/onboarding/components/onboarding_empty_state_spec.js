import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import OnboardingEmptyState from 'ee/product_analytics/onboarding/components/onboarding_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import { EMPTY_STATE_I18N } from 'ee/product_analytics/onboarding/constants';
import initializeProductAnalyticsMutation from 'ee/product_analytics/graphql/mutations/initialize_product_analytics.mutation.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import { createInstanceResponse, TEST_PROJECT_FULL_PATH } from '../../mock_data';

Vue.use(VueApollo);

describe('OnboardingEmptyState', () => {
  let wrapper;

  const fatalError = new Error('GraphQL networkError');
  const apiErrorMsg = 'Product analytics initialization is already complete';
  const mockApolloLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const mockApolloSuccess = jest.fn().mockResolvedValue(createInstanceResponse([]));
  const mockApolloApiError = jest.fn().mockResolvedValue(createInstanceResponse([apiErrorMsg]));
  const mockApolloFatalError = jest.fn().mockRejectedValue(fatalError);

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findSetupBtn = () => wrapper.findByTestId('setup-btn');
  const findLearnMoreBtn = () => wrapper.findByTestId('learn-more-btn');

  const createWrapper = (props = {}, handlers) => {
    wrapper = shallowMountExtended(OnboardingEmptyState, {
      apolloProvider: createMockApollo(handlers),
      propsData: {
        loadingInstance: false,
        ...props,
      },
      provide: {
        chartEmptyStateIllustrationPath: TEST_HOST,
        projectFullPath: TEST_PROJECT_FULL_PATH,
      },
    });
  };

  const createAndInitializeWithMock = (mock) => {
    createWrapper({}, [[initializeProductAnalyticsMutation, mock]]);

    findSetupBtn().vm.$emit('click');

    return waitForPromises();
  };

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper({}, [[initializeProductAnalyticsMutation, mockApolloSuccess]]);
    });

    it('should render the empty state with expected props', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props()).toMatchObject({
        title: EMPTY_STATE_I18N.empty.title,
        svgPath: TEST_HOST,
      });
      expect(emptyState.text()).toContain(EMPTY_STATE_I18N.empty.description);
      expect(findSetupBtn().text()).toBe(EMPTY_STATE_I18N.empty.setUpBtnText);
      expect(findLearnMoreBtn().text()).toBe(EMPTY_STATE_I18N.empty.learnMoreBtnText);
      expect(findLearnMoreBtn().attributes('href')).toBe('/help/user/product_analytics/index');
    });

    it('should emit `initialized` when the setup button is clicked', async () => {
      findSetupBtn().vm.$emit('click');

      await waitForPromises();

      expect(wrapper.emitted('initialized')).toStrictEqual([[]]);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe.each`
    scenario               | createScenario
    ${'loading'}           | ${() => createWrapper({ loadingInstance: true })}
    ${'being initialized'} | ${() => createAndInitializeWithMock(mockApolloLoading)}
  `('when the instance is $scenario', ({ createScenario }) => {
    beforeEach(() => {
      return createScenario();
    });

    it('should render the empty state with loading text', () => {
      const emptyState = findEmptyState();

      expect(emptyState.props()).toMatchObject({
        title: EMPTY_STATE_I18N.loading.title,
        svgPath: TEST_HOST,
      });
      expect(emptyState.text()).toContain(EMPTY_STATE_I18N.loading.description);
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the buttons', () => {
      expect(findSetupBtn().exists()).toBe(false);
      expect(findLearnMoreBtn().exists()).toBe(false);
    });
  });

  describe.each`
    type       | error                     | apolloMock
    ${'api'}   | ${new Error(apiErrorMsg)} | ${mockApolloApiError}
    ${'fatal'} | ${fatalError}             | ${mockApolloFatalError}
  `('when there is a $type error', ({ error, apolloMock }) => {
    beforeEach(() => {
      return createAndInitializeWithMock(apolloMock);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('emits the captured error', () => {
      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });
});
