import ProductAnalyticsSetupView from 'ee/product_analytics/onboarding/onboarding_setup.vue';
import OnboardingKeyInput from 'ee/product_analytics/onboarding/components/onboarding_key_input.vue';
import OnboardingSetupCollapse from 'ee/product_analytics/onboarding/components/onboarding_setup_collapse.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'spec/test_constants';
import {
  ESM_SETUP_WITH_NPM,
  COMMON_JS_SETUP_WITH_NPM,
  HTML_SCRIPT_SETUP,
} from 'ee/product_analytics/onboarding/constants';

const TEST_JITSU_HOST = TEST_HOST;
const TEST_JITSU_PROJECT_ID = 'gitlab-org/gitlab';

describe('ProductAnalyticsSetupView', () => {
  let wrapper;

  const findTitle = () => wrapper.findByTestId('title');
  const findDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findIntroduction = () => wrapper.findByTestId('introduction');
  const findKeyInputAt = (index) => wrapper.findAllComponents(OnboardingKeyInput).at(index);
  const findInstructionsAt = (index) =>
    wrapper.findAllComponents(OnboardingSetupCollapse).at(index);

  const createWrapper = () => {
    wrapper = mountExtended(ProductAnalyticsSetupView, {
      provide: {
        jitsuHost: TEST_JITSU_HOST,
        jitsuProjectId: TEST_JITSU_PROJECT_ID,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the heading section', () => {
      expect(findTitle().text()).toContain(ProductAnalyticsSetupView.i18n.title);
      expect(findDescription().text()).toContain(ProductAnalyticsSetupView.i18n.description);
      expect(findHelpLink().text()).toContain(ProductAnalyticsSetupView.i18n.learnMore);
      expect(findHelpLink().attributes('href')).toBe(ProductAnalyticsSetupView.docsPath);
      expect(findIntroduction().text()).toContain(ProductAnalyticsSetupView.i18n.introduction);
    });

    it.each`
      key                      | index
      ${TEST_JITSU_HOST}       | ${0}
      ${TEST_JITSU_PROJECT_ID} | ${1}
    `('should render key inputs at $index', ({ key, index }) => {
      expect(findKeyInputAt(index).props('value')).toBe(key);
    });

    it.each`
      instructions                | index
      ${ESM_SETUP_WITH_NPM}       | ${0}
      ${COMMON_JS_SETUP_WITH_NPM} | ${1}
      ${HTML_SCRIPT_SETUP}        | ${2}
    `('should render instructions at $index', ({ instructions, index }) => {
      const instructionsWithKeys = wrapper.vm.replaceKeys(instructions);

      expect(findInstructionsAt(index).text()).toContain(instructionsWithKeys);
    });
  });
});
