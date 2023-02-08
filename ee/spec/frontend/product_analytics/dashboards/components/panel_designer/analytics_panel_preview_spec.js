import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsPanelPreview from 'ee/product_analytics/dashboards/components/panel_designer/analytics_panel_preview.vue';

import { PANEL_DISPLAY_TYPES } from 'ee/product_analytics/dashboards/constants';

describe('AnalyticsPanelPreview', () => {
  let wrapper;

  const findDataButton = () => wrapper.findByTestId('select-data-button');
  const findPanelButton = () => wrapper.findByTestId('select-panel-button');
  const findCodeButton = () => wrapper.findByTestId('select-code-button');

  const selectDisplayType = jest.fn();

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(AnalyticsPanelPreview, {
      propsData: {
        selectedVisualizationType: '',
        displayType: '',
        selectDisplayType,
        isQueryPresent: false,
        loading: false,
        resultSet: { tablePivot: () => {} },
        resultPanel: {},
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render measurement headline', () => {
      expect(wrapper.findByTestId('measurement-hl').exists()).toBe(true);
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createWrapper({ isQueryPresent: true, loading: true });
    });

    it('should render loading icon', () => {
      expect(wrapper.findByTestId('loading-icon').exists()).toBe(true);
    });
  });

  describe('when it has a resultSet', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
      });
    });

    it('should render overview buttons', () => {
      expect(findDataButton().exists()).toBe(true);
      expect(findPanelButton().exists()).toBe(true);
      expect(findCodeButton().exists()).toBe(true);
    });

    it('should be able to select data section', () => {
      findDataButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[PANEL_DISPLAY_TYPES.DATA]]);
    });

    it('should be able to select panel section', () => {
      findPanelButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[PANEL_DISPLAY_TYPES.PANEL]]);
    });

    it('should be able to select code section', () => {
      findCodeButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[PANEL_DISPLAY_TYPES.CODE]]);
    });
  });

  describe('resultSet and data is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: PANEL_DISPLAY_TYPES.DATA,
      });
    });

    it('should render data table', () => {
      expect(wrapper.findByTestId('preview-datatable').exists()).toBe(true);
    });
  });

  describe('resultSet and panel is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: PANEL_DISPLAY_TYPES.PANEL,
        selectedVisualizationType: 'LineChart',
      });
    });

    it('should render panel', () => {
      expect(wrapper.findByTestId('preview-panel').exists()).toBe(true);
    });
  });

  describe('resultSet and code is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: PANEL_DISPLAY_TYPES.CODE,
      });
    });

    it('should render Code', () => {
      expect(wrapper.findByTestId('preview-code').exists()).toBe(true);
    });
  });
});
