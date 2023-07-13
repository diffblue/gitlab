import InstrumentationInstructions from 'ee/product_analytics/onboarding/components/instrumentation_instructions.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  HTML_SCRIPT_SETUP,
  IMPORT_NPM_PACKAGE,
  INIT_TRACKING,
  INSTALL_NPM_PACKAGE,
} from 'ee/product_analytics/onboarding/constants';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';
import { s__ } from '~/locale';

describe('ProductAnalyticsInstrumentationInstructions', () => {
  let wrapper;

  const findNpmInstructions = () => wrapper.findByTestId('npm-instrumentation-instructions');
  const findHtmlInstructions = () => wrapper.findByTestId('html-instrumentation-instructions');
  const findFurtherBrowserSDKInfo = () => wrapper.findByTestId('further-browser-sdk-info');
  const findSummaryText = () => wrapper.findByTestId('summary-text');

  const createWrapper = (props = {}, provide = {}) => {
    wrapper = shallowMountExtended(InstrumentationInstructions, {
      propsData: {
        trackingKey: TEST_TRACKING_KEY,
        dashboardsPath: '/foo/bar/dashboards',
        ...props,
      },
      provide: {
        collectorHost: TEST_COLLECTOR_HOST,
        ...provide,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => createWrapper());

    it('renders the expected instructions', () => {
      const initInstructionsWithKeys = wrapper.vm.replaceKeys(INIT_TRACKING);
      const htmlInstructionsWithKeys = wrapper.vm.replaceKeys(HTML_SCRIPT_SETUP);

      const npmInstructions = findNpmInstructions().text();
      const htmlInstructions = findHtmlInstructions().text();

      expect(npmInstructions).toContain(INSTALL_NPM_PACKAGE);
      expect(npmInstructions).toContain(IMPORT_NPM_PACKAGE);
      expect(npmInstructions).toContain(initInstructionsWithKeys);
      expect(htmlInstructions).toContain(htmlInstructionsWithKeys);
    });

    describe('static text', () => {
      it('renders the further browser SDK info text', () => {
        expect(findFurtherBrowserSDKInfo().attributes('message')).toBe(
          s__('ProductAnalytics|For more information, see the %{linkStart}docs%{linkEnd}.'),
        );
      });

      it('renders the summary text', () => {
        expect(findSummaryText().attributes('message')).toBe(
          s__(
            'ProductAnalytics|After your application has been instrumented and data is being collected, you can visualize and monitor behaviors in your %{linkStart}analytics dashboards%{linkEnd}.',
          ),
        );
      });
    });
  });
});
