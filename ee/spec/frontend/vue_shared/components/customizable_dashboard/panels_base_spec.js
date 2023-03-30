import { GlLoadingIcon } from '@gitlab/ui';
import LineChart from 'ee/analytics/analytics_dashboards/components/visualizations/line_chart.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PanelsBase from 'ee/vue_shared/components/customizable_dashboard/panels_base.vue';
import dataSources from 'ee/analytics/analytics_dashboards/data_sources';
import waitForPromises from 'helpers/wait_for_promises';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import { I18N_PANEL_EMPTY_STATE_MESSAGE } from 'ee/vue_shared/components/customizable_dashboard/constants';
import { dashboard } from './mock_data';

jest.mock('ee/analytics/analytics_dashboards/data_sources', () => ({
  cube_analytics: jest.fn().mockReturnValue({
    fetch: jest.fn().mockReturnValue([]),
  }),
}));

describe('PanelsBase', () => {
  const panelConfig = dashboard.panels[0];

  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(PanelsBase, {
      provide: { projectId: '1' },
      propsData: {
        title: panelConfig.title,
        visualization: panelConfig.visualization,
        queryOverrides: panelConfig.queryOverrides,
        ...props,
      },
    });
  };

  const findVisualization = () => wrapper.findComponent(LineChart);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPanelTitle = () => wrapper.findComponent(TooltipOnTruncate);

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render title', () => {
      expect(findPanelTitle().props()).toMatchObject({
        placement: 'top',
        title: panelConfig.title,
        boundary: 'viewport',
      });
      expect(findPanelTitle().text()).toBe(panelConfig.title);
    });

    it('should call the data source', () => {
      expect(dataSources.cube_analytics).toHaveBeenCalled();
    });
  });

  describe('when fetching the data', () => {
    beforeEach(() => {
      jest.spyOn(dataSources.cube_analytics(), 'fetch').mockReturnValue(new Promise(() => {}));
      createWrapper();
      return waitForPromises();
    });

    it('should render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('should not render the visualization', () => {
      expect(findVisualization().exists()).toBe(false);
    });
  });

  describe('when the data has been fetched', () => {
    describe('and there is data', () => {
      const mockData = [{ name: 'foo' }];

      beforeEach(() => {
        jest.spyOn(dataSources.cube_analytics(), 'fetch').mockReturnValue(mockData);
        createWrapper();
        return waitForPromises();
      });

      it('should not render the loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('should not render the empty state', () => {
        expect(wrapper.text()).not.toContain(I18N_PANEL_EMPTY_STATE_MESSAGE);
      });

      it('should render the visualization with the fetched data', () => {
        expect(findVisualization().props()).toMatchObject({
          data: mockData,
          options: panelConfig.visualization.options,
        });
      });
    });

    describe('and there is no data', () => {
      beforeEach(() => {
        jest.spyOn(dataSources.cube_analytics(), 'fetch').mockReturnValue(undefined);
        createWrapper();
        return waitForPromises();
      });

      it('should not render the loading icon', () => {
        expect(findLoadingIcon().exists()).toBe(false);
      });

      it('should render the empty state', () => {
        const text = wrapper.text();
        expect(text).toContain(I18N_PANEL_EMPTY_STATE_MESSAGE);
      });
    });
  });

  describe('when there was an error while fetching the data', () => {
    const mockError = new Error('foo');

    beforeEach(() => {
      jest.spyOn(dataSources.cube_analytics(), 'fetch').mockRejectedValue(mockError);
      createWrapper();
      return waitForPromises();
    });

    it('should not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should not render the empty state', () => {
      expect(wrapper.text()).not.toContain(I18N_PANEL_EMPTY_STATE_MESSAGE);
    });

    it('should not render the visualization', () => {
      expect(findVisualization().exists()).toBe(false);
    });

    it('should emit an error event', () => {
      expect(wrapper.emitted('error')[0]).toStrictEqual([mockError]);
    });
  });

  describe('when provided with filters', () => {
    const filters = {
      dateRange: {
        startDate: new Date('2015-01-01'),
        endDate: new Date('2016-01-01'),
      },
    };

    beforeEach(() => {
      jest.spyOn(dataSources.cube_analytics(), 'fetch').mockReturnValue(new Promise(() => {}));
      createWrapper({ filters });
      return waitForPromises();
    });

    it('should call fetch on the data source with the filters', () => {
      expect(dataSources.cube_analytics().fetch).toHaveBeenCalledWith(
        expect.objectContaining({ filters }),
      );
    });
  });

  describe('when the panel has no title', () => {
    beforeEach(() => {
      createWrapper({ title: null });
    });

    it('should not render the title', () => {
      expect(findPanelTitle().exists()).toBe(false);
    });
  });
});
