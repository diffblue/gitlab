import * as utils from 'ee/analytics/analytics_dashboards/utils';
import { TEST_VISUALIZATION } from 'ee_jest/analytics/analytics_dashboards/mock_data';

describe('Analytics dashboard utils', () => {
  describe('#createNewVisualizationPanel', () => {
    it('returns the expected object', () => {
      const visualization = TEST_VISUALIZATION();
      expect(utils.createNewVisualizationPanel(visualization)).toMatchObject({
        visualization,
        title: 'Test visualization',
        gridAttributes: {
          width: 4,
          height: 3,
        },
        options: {},
      });
    });
  });
});
