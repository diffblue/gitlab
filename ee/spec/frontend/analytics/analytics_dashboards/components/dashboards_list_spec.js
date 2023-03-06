import DashboardsList from 'ee/analytics/analytics_dashboards/components/dashboards_list.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  I18N_DASHBOARD_LIST_TITLE,
  I18N_DASHBOARD_LIST_DESCRIPTION,
  I18N_DASHBOARD_LIST_LEARN_MORE,
  I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS,
} from 'ee/analytics/analytics_dashboards/constants';
import jsonList from 'ee/analytics/analytics_dashboards/gl_dashboards/analytics_dashboards.json';
import { helpPagePath } from '~/helpers/help_page_helper';
import AnalyticsClipboardInput from 'ee/product_analytics/shared/analytics_clipboard_input.vue';

import { getCustomDashboards } from 'ee/analytics/analytics_dashboards/api/dashboards_api';
import {
  TEST_COLLECTOR_HOST,
  TEST_JITSU_KEY,
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_CUSTOM_DASHBOARDS_LIST,
} from '../mock_data';

jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api');

describe('DashboardsList', () => {
  let wrapper;

  const findRouterDescriptions = () => wrapper.findAllByTestId('dashboard-description');
  const findRouterLinks = () => wrapper.findAllByTestId('dashboard-link');
  const findRouterIcons = () => wrapper.findAllByTestId('dashboard-icon');
  const findRouterLabels = () => wrapper.findAllByTestId('dashboard-label');
  const findListItems = () => wrapper.findAllByTestId('dashboard-list-item');
  const findPageTitle = () => wrapper.findByTestId('title');
  const findPageDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findVisualizationDesignerButton = () =>
    wrapper.findByTestId('visualization-designer-button');
  const findInstrumentationDetailsDropdown = () =>
    wrapper.findByTestId('intrumentation-details-dropdown');
  const findKeyInputAt = (index) => wrapper.findAllComponents(AnalyticsClipboardInput).at(index);

  const NUMBER_OF_DASHBOARDS = jsonList.productAnalytics.length + 1;

  const $router = {
    push: jest.fn(),
  };

  const createWrapper = (provided = {}) => {
    wrapper = shallowMountExtended(DashboardsList, {
      stubs: {
        RouterLink: true,
      },
      mocks: {
        $router,
      },
      provide: {
        collectorHost: TEST_COLLECTOR_HOST,
        jitsuKey: TEST_JITSU_KEY,
        customDashboardsProject: TEST_CUSTOM_DASHBOARDS_PROJECT,
        ...provided,
      },
    });
  };

  beforeEach(() => {
    getCustomDashboards.mockImplementation(() => TEST_CUSTOM_DASHBOARDS_LIST);
  });

  describe('by default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page title', () => {
      expect(findPageTitle().text()).toBe(I18N_DASHBOARD_LIST_TITLE);
    });

    it('should render the page description', () => {
      expect(findPageDescription().text()).toContain(I18N_DASHBOARD_LIST_DESCRIPTION);
    });

    it('should render the visualization designer button', () => {
      expect(findVisualizationDesignerButton().exists()).toBe(true);
    });

    it('should render the instrumentation details dropdown', () => {
      expect(findInstrumentationDetailsDropdown().attributes()).toMatchObject({
        text: I18N_DASHBOARD_LIST_INSTRUMENTATION_DETAILS,
        'split-to': 'setup',
        split: 'true',
      });

      expect(findKeyInputAt(0).props('value')).toBe(TEST_COLLECTOR_HOST);
      expect(findKeyInputAt(1).props('value')).toBe(TEST_JITSU_KEY);
    });

    it('should render the help link', () => {
      expect(findHelpLink().text()).toBe(I18N_DASHBOARD_LIST_LEARN_MORE);
      expect(findHelpLink().attributes('href')).toBe(
        helpPagePath('user/product_analytics/index', {
          anchor: 'product-analytics-dashboards',
        }),
      );
    });

    it('does not render any feature dashboards', () => {
      expect(findRouterLinks()).toHaveLength(1);
    });
  });

  describe('when the feature dashboards are enabled', () => {
    beforeEach(() => {
      createWrapper({ features: { productAnalytics: true } });
    });

    it('should render titles of pre-built dashboards', () => {
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterLinks().at(0).text()).toContain('Audience');
    });

    it('should render titles of custom dashboard', () => {
      expect(getCustomDashboards).toHaveBeenCalledWith(TEST_CUSTOM_DASHBOARDS_PROJECT);
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterLinks().at(2).text()).toContain('new_dashboard');
    });

    it('should render descriptions', () => {
      expect(findRouterDescriptions()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterDescriptions().at(0).text()).toContain('Understand your audience');
    });

    it('should render links', () => {
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
    });

    it('should render icons', () => {
      expect(findRouterIcons().at(0).props('name')).toBe('project');
    });

    it('should render label', () => {
      expect(findRouterLabels()).toHaveLength(1);
      expect(findRouterLabels().at(0).props('title')).toBe('Audience');
    });

    it('should route to the dashboard when a list item is clicked', async () => {
      await findListItems().at(0).trigger('click');

      expect($router.push).toHaveBeenCalledWith('dashboard_audience');
    });
  });

  describe('when the instrumentation details button is disabled', () => {
    beforeEach(() => {
      createWrapper({ showInstrumentationDetailsButton: false });
    });

    it('should not render the instrumentation details dropdown', () => {
      expect(findInstrumentationDetailsDropdown().exists()).toBe(false);
    });
  });
});
