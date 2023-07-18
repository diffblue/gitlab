import * as utils from 'ee/analytics/analytics_dashboards/utils';
import { TEST_VISUALIZATION } from 'ee_jest/analytics/analytics_dashboards/mock_data';

describe('Analytics dashboard utils', () => {
  describe('#getNextPanelId', () => {
    it('returns 1 when there are no panels', () => {
      expect(utils.getNextPanelId([])).toBe(1);
    });

    it('returns 1 when there are no number IDs', () => {
      const panels = [{ id: 'a' }, { id: 'b' }];
      expect(utils.getNextPanelId(panels)).toBe(1);
    });

    it('returns the next ID when there are numbered IDs', () => {
      const panels = [{ id: 1 }, { id: 2 }];
      expect(utils.getNextPanelId(panels)).toBe(3);
    });
  });

  describe('#createNewVisualizationPanel', () => {
    it('returns the expected object', () => {
      const visualization = TEST_VISUALIZATION();
      expect(utils.createNewVisualizationPanel(1, visualization)).toMatchObject({
        id: 1,
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
