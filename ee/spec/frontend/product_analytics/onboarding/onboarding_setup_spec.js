import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ProductAnalyticsSetupView from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import InstrumentationInstructions from 'ee/product_analytics/onboarding/components/instrumentation_instructions.vue';
import getProjectJitsuKeyQuery from 'ee/product_analytics/graphql/queries/get_project_tracking_key.query.graphql';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getTrackingKeyResponse, TEST_PROJECT_FULL_PATH } from '../mock_data';

const { i18n } = ProductAnalyticsSetupView;

Vue.use(VueApollo);

describe('ProductAnalyticsSetupView', () => {
  let wrapper;

  const fatalError = new Error('GraphQL networkError');
  const defaultProps = {
    isInitialSetup: false,
    dashboardsPath: '/path/to/dashboard',
  };

  const mockApolloFatalError = jest.fn().mockRejectedValue(fatalError);
  const mockApolloSuccess = jest.fn().mockResolvedValue(getTrackingKeyResponse(TEST_TRACKING_KEY));

  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findIntroduction = () => wrapper.findByTestId('introduction');
  const findBackToDashboardsButton = () => wrapper.findByTestId('back-to-dashboards-button');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInstrumentationInstructions = () => wrapper.findComponent(InstrumentationInstructions);

  const createWrapper = (props = {}, provide = {}, apolloMock = mockApolloSuccess) => {
    wrapper = mountExtended(ProductAnalyticsSetupView, {
      apolloProvider: createMockApollo([[getProjectJitsuKeyQuery, apolloMock]]),
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        namespaceFullPath: TEST_PROJECT_FULL_PATH,
        collectorHost: TEST_COLLECTOR_HOST,
        trackingKey: TEST_TRACKING_KEY,
        ...provide,
      },
    });
  };

  describe('when mounted', () => {
    it('should render the heading section', () => {
      createWrapper();

      expect(findTitle().text()).toContain(i18n.title);
      expect(findHelpLink().text()).toContain(i18n.learnMore);
      expect(findHelpLink().attributes('href')).toBe(ProductAnalyticsSetupView.docsPath);
    });

    it('does not render the loading icon', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    it.each`
      isInitialSetup | description
      ${true}        | ${i18n.initialSetupDescription}
      ${false}       | ${i18n.description}
    `(
      'should render the right heading when "isInitialSetup" is "$isInitialSetup"',
      ({ isInitialSetup, description }) => {
        createWrapper({ isInitialSetup });

        expect(findDescription().text()).toContain(description);
        expect(findIntroduction().exists()).toBe(isInitialSetup);
        expect(findBackToDashboardsButton().exists()).toBe(!isInitialSetup);
      },
    );
  });

  describe('when no trackingKey is provided', () => {
    it('displays the loading icon', () => {
      createWrapper({}, { trackingKey: null });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays the instrumentation instructions when the query succeeds', async () => {
      createWrapper({}, { trackingKey: null });

      await waitForPromises();

      const instrumentationInstructions = findInstrumentationInstructions();

      expect(instrumentationInstructions.exists()).toBe(true);
      expect(instrumentationInstructions.props('trackingKey')).toBe(TEST_TRACKING_KEY);
    });

    it('emits an error when the query errors', async () => {
      createWrapper({}, { trackingKey: null }, mockApolloFatalError);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[fatalError]]);
    });
  });
});
