import AnalyticsVisualizationPreview from 'ee/analytics/analytics_dashboards/components/visualization_designer/analytics_visualization_preview.vue';

import {
  PANEL_DISPLAY_TYPES,
  PANEL_VISUALIZATION_HEIGHT,
} from 'ee/analytics/analytics_dashboards/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('AnalyticsVisualizationPreview', () => {
  let wrapper;

  const findDataButton = () => wrapper.findByTestId('select-data-button');
  const findVisualizationButton = () => wrapper.findByTestId('select-visualization-button');
  const findCodeButton = () => wrapper.findByTestId('select-code-button');

  const selectDisplayType = jest.fn();

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(AnalyticsVisualizationPreview, {
      propsData: {
        selectedVisualizationType: '',
        displayType: '',
        selectDisplayType,
        isQueryPresent: false,
        loading: false,
        resultSet: { tablePivot: () => {} },
        resultVisualization: {},
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
      expect(findVisualizationButton().exists()).toBe(true);
      expect(findCodeButton().exists()).toBe(true);
    });

    it('should be able to select data section', () => {
      findDataButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[PANEL_DISPLAY_TYPES.DATA]]);
    });

    it('should be able to select visualization section', () => {
      findVisualizationButton().vm.$emit('click');
      expect(wrapper.emitted('selectedDisplayType')).toEqual([[PANEL_DISPLAY_TYPES.VISUALIZATION]]);
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

  describe('resultSet and visualization is selected', () => {
    beforeEach(() => {
      createWrapper({
        isQueryPresent: true,
        displayType: PANEL_DISPLAY_TYPES.VISUALIZATION,
        selectedVisualizationType: 'LineChart',
      });
    });

    it('should render visualization', () => {
      expect(wrapper.findByTestId('preview-visualization').attributes('style')).toBe(
        `height: ${PANEL_VISUALIZATION_HEIGHT};`,
      );
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
