import { __setMockMetadata } from '@cubejs-client/core';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsWidgetDesigner from 'ee/product_analytics/dashboards/components/analytics_widget_designer.vue';
import { mockMetaData } from './mock_data';

describe('AnalyticsWidgetDesigner', () => {
  let wrapper;

  const findTitleInput = () => wrapper.findByTestId('widget-title-tba');
  const findDimensionSelector = () => wrapper.findByTestId('widget-dimension-selector');

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsWidgetDesigner);
  };

  describe('when mounted', () => {
    beforeEach(() => {
      __setMockMetadata(jest.fn().mockImplementation(() => mockMetaData));
      createWrapper();
    });

    it('should render title box', () => {
      expect(findTitleInput().exists()).toBe(true);
    });

    it('should not render dimension selector', () => {
      expect(findDimensionSelector().exists()).toBe(false);
    });
  });
});
