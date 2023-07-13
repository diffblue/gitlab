import InstrumentationInstructionsSdkDetails from 'ee/product_analytics/onboarding/components/instrumentation_instructions_sdk_details.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import {
  TEST_COLLECTOR_HOST,
  TEST_TRACKING_KEY,
} from 'ee_jest/analytics/analytics_dashboards/mock_data';

describe('ProductAnalyticsInstrumentationInstructionsSdkDetails', () => {
  let wrapper;

  const findInputByValue = (value) => wrapper.findByDisplayValue(value);

  const createWrapper = (props = {}, provide = {}) => {
    wrapper = mountExtended(InstrumentationInstructionsSdkDetails, {
      propsData: {
        trackingKey: TEST_TRACKING_KEY,
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

    it('renders the SDK host', () => {
      expect(findInputByValue(TEST_COLLECTOR_HOST).exists()).toBe(true);
    });

    it('renders the SDK appId', () => {
      expect(findInputByValue(TEST_TRACKING_KEY).exists()).toBe(true);
    });
  });
});
