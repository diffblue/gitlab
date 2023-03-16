import { __setMockMetadata } from '@cubejs-client/core';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import AnalyticsVisualizationDesigner from 'ee/analytics/analytics_dashboards/components/analytics_visualization_designer.vue';
import { mockMetaData } from '../mock_data';

describe('AnalyticsVisualizationDesigner', () => {
  let wrapper;

  const findTitleInput = () => wrapper.findByTestId('panel-title-tba');
  const findDimensionSelector = () => wrapper.findByTestId('panel-dimension-selector');

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsVisualizationDesigner);
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
