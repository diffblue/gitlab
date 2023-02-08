import { GlLoadingIcon } from '@gitlab/ui';
import LineChart from 'ee/product_analytics/dashboards/components/visualizations/line_chart.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PanelsBase from 'ee/vue_shared/components/customizable_dashboard/panels_base.vue';
import dataSources from 'ee/product_analytics/dashboards/data_sources';
import waitForPromises from 'helpers/wait_for_promises';
import { dashboard } from './mock_data';

jest.mock('ee/product_analytics/dashboards/data_sources', () => ({
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
  const findPanelTitle = () => wrapper.findByTestId('panel-title');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default behaviour', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render title', () => {
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
    const mockData = [{ name: 'foo' }];

    beforeEach(() => {
      jest.spyOn(dataSources.cube_analytics(), 'fetch').mockReturnValue(mockData);
      createWrapper();
      return waitForPromises();
    });

    it('should not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should render the visualization with the fetched data', () => {
      expect(findVisualization().props()).toMatchObject({
        data: mockData,
        options: panelConfig.visualization.options,
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

    it('should not render the visualization', () => {
      expect(findVisualization().exists()).toBe(false);
    });

    it('should emit an error event', () => {
      expect(wrapper.emitted('error')[0]).toStrictEqual([mockError]);
    });
  });
});
