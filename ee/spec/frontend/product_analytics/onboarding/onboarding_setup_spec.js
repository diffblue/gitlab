import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import ProductAnalyticsSetupView from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import AnalyticsClipboardInput from 'ee/product_analytics/shared/analytics_clipboard_input.vue';
import OnboardingSetupCollapse from 'ee/product_analytics/onboarding/components/onboarding_setup_collapse.vue';
import getProjectJitsuKeyQuery from 'ee/product_analytics/graphql/queries/get_project_tracking_key.query.graphql';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  ESM_SETUP_WITH_NPM,
  COMMON_JS_SETUP_WITH_NPM,
  HTML_SCRIPT_SETUP,
} from 'ee/product_analytics/onboarding/constants';
import {
  TEST_TRACKING_KEY,
  TEST_COLLECTOR_HOST,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import createMockApollo from 'helpers/mock_apollo_helper';
import { getTrackingKeyResponse, TEST_PROJECT_FULL_PATH } from '../mock_data';

const { i18n } = ProductAnalyticsSetupView;

Vue.use(VueApollo);

describe('ProductAnalyticsSetupView', () => {
  let wrapper;

  const fatalError = new Error('GraphQL networkError');
  const jitsuKey = 'valid-jitsu-key';

  const mockApolloFatalError = jest.fn().mockRejectedValue(fatalError);
  const mockApolloSuccess = jest.fn().mockResolvedValue(getTrackingKeyResponse(jitsuKey));

  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findIntroduction = () => wrapper.findByTestId('introduction');
  const findBackToDashboardsButton = () => wrapper.findByTestId('back-to-dashboards-button');
  const findKeyInputAt = (index) => wrapper.findAllComponents(AnalyticsClipboardInput).at(index);
  const findInstructionsAt = (index) =>
    wrapper.findAllComponents(OnboardingSetupCollapse).at(index);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createWrapper = (props = {}, provide = {}, apolloMock = mockApolloSuccess) => {
    wrapper = mountExtended(ProductAnalyticsSetupView, {
      apolloProvider: createMockApollo([[getProjectJitsuKeyQuery, apolloMock]]),
      propsData: {
        isInitialSetup: false,
        ...props,
      },
      provide: {
        projectFullPath: TEST_PROJECT_FULL_PATH,
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

    it.each`
      key                    | index
      ${TEST_COLLECTOR_HOST} | ${0}
      ${TEST_TRACKING_KEY}   | ${1}
    `('should render key inputs at $index', ({ key, index }) => {
      createWrapper();

      expect(findKeyInputAt(index).props('value')).toBe(key);
    });

    it.each`
      instructions                | index | snowplowFeatureEnabled
      ${ESM_SETUP_WITH_NPM}       | ${0}  | ${false}
      ${COMMON_JS_SETUP_WITH_NPM} | ${1}  | ${false}
      ${HTML_SCRIPT_SETUP}        | ${2}  | ${false}
      ${ESM_SETUP_WITH_NPM}       | ${0}  | ${true}
      ${COMMON_JS_SETUP_WITH_NPM} | ${1}  | ${true}
      ${HTML_SCRIPT_SETUP}        | ${2}  | ${true}
    `('should render instructions at $index', ({ instructions, index, snowplowFeatureEnabled }) => {
      createWrapper(
        {},
        {
          glFeatures: {
            productAnalyticsSnowplowSupport: snowplowFeatureEnabled,
          },
        },
      );

      const instructionsWithKeys = wrapper.vm.replaceKeys(instructions);

      expect(findInstructionsAt(index).text()).toContain(instructionsWithKeys);
    });
  });

  describe('when no trackingKey is provided', () => {
    it('displays the loading icon', () => {
      createWrapper({}, { trackingKey: null });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('displays the fetched key when the query succeeds', async () => {
      createWrapper({}, { trackingKey: null });

      await waitForPromises();

      expect(findKeyInputAt(1).props('value')).toBe(jitsuKey);
    });

    it('emits an error when the query errors', async () => {
      createWrapper({}, { trackingKey: null }, mockApolloFatalError);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[fatalError]]);
    });
  });
});
