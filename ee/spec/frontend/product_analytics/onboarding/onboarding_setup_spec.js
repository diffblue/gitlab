import ProductAnalyticsSetupView from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import AnalyticsClipboardInput from 'ee/product_analytics/shared/analytics_clipboard_input.vue';
import OnboardingSetupCollapse from 'ee/product_analytics/onboarding/components/onboarding_setup_collapse.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  ESM_SETUP_WITH_NPM,
  COMMON_JS_SETUP_WITH_NPM,
  HTML_SCRIPT_SETUP,
} from 'ee/product_analytics/onboarding/constants';
import { TEST_JITSU_HOST, TEST_JITSU_PROJECT_ID } from '../mock_data';

const { i18n } = ProductAnalyticsSetupView;

describe('ProductAnalyticsSetupView', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findIntroduction = () => wrapper.findByTestId('introduction');
  const findBackToDashboardsButton = () => wrapper.findByTestId('back-to-dashboards-button');
  const findKeyInputAt = (index) => wrapper.findAllComponents(AnalyticsClipboardInput).at(index);
  const findInstructionsAt = (index) =>
    wrapper.findAllComponents(OnboardingSetupCollapse).at(index);

  const createWrapper = ({ isInitialSetup = false } = {}) => {
    wrapper = mountExtended(ProductAnalyticsSetupView, {
      propsData: {
        isInitialSetup,
      },
      provide: {
        jitsuHost: TEST_JITSU_HOST,
        jitsuProjectId: TEST_JITSU_PROJECT_ID,
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
      key                      | index
      ${TEST_JITSU_HOST}       | ${0}
      ${TEST_JITSU_PROJECT_ID} | ${1}
    `('should render key inputs at $index', ({ key, index }) => {
      createWrapper();

      expect(findKeyInputAt(index).props('value')).toBe(key);
    });

    it.each`
      instructions                | index
      ${ESM_SETUP_WITH_NPM}       | ${0}
      ${COMMON_JS_SETUP_WITH_NPM} | ${1}
      ${HTML_SCRIPT_SETUP}        | ${2}
    `('should render instructions at $index', ({ instructions, index }) => {
      createWrapper();

      const instructionsWithKeys = wrapper.vm.replaceKeys(instructions);

      expect(findInstructionsAt(index).text()).toContain(instructionsWithKeys);
    });
  });
});
