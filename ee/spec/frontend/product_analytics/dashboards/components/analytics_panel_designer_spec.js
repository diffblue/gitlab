import { __setMockMetadata } from '@cubejs-client/core';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsPanelDesigner from 'ee/product_analytics/dashboards/components/analytics_panel_designer.vue';
import { mockMetaData } from './mock_data';

describe('AnalyticsPanelDesigner', () => {
  let wrapper;

  const findTitleInput = () => wrapper.findByTestId('panel-title-tba');
  const findDimensionSelector = () => wrapper.findByTestId('panel-dimension-selector');

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsPanelDesigner);
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
