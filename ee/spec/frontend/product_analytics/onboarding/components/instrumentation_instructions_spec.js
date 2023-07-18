import InstrumentationInstructions from 'ee/product_analytics/onboarding/components/instrumentation_instructions.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { IMPORT_NPM_PACKAGE, INSTALL_NPM_PACKAGE } from 'ee/product_analytics/onboarding/constants';
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

  const createWrapper = (mountFn = shallowMountExtended) => {
    wrapper = mountFn(InstrumentationInstructions, {
      propsData: {
        trackingKey: TEST_TRACKING_KEY,
        dashboardsPath: '/foo/bar/dashboards',
      },
      provide: {
        collectorHost: TEST_COLLECTOR_HOST,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => createWrapper());

    it('renders the expected instructions', () => {
      createWrapper(mountExtended);

      const expectedAppIdFragment = `appId: '${TEST_TRACKING_KEY}'`;
      const expectedHostFragment = `host: '${TEST_COLLECTOR_HOST}'`;

      const npmInstructions = findNpmInstructions().text();
      expect(npmInstructions).toContain(INSTALL_NPM_PACKAGE);
      expect(npmInstructions).toContain(IMPORT_NPM_PACKAGE);
      expect(npmInstructions).toContain(expectedAppIdFragment);
      expect(npmInstructions).toContain(expectedHostFragment);

      const htmlInstructions = findHtmlInstructions().text();
      expect(htmlInstructions).toContain(expectedAppIdFragment);
      expect(htmlInstructions).toContain(expectedHostFragment);
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
