import DashboardsList from 'ee/analytics/analytics_dashboards/components/dashboards_list.vue';
import DashboardListItem from 'ee/analytics/analytics_dashboards/components/list/dashboard_list_item.vue';
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

  const findListItems = () => wrapper.findAllComponents(DashboardListItem);
  const findPageTitle = () => wrapper.findByTestId('title');
  const findPageDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findVisualizationDesignerButton = () =>
    wrapper.findByTestId('visualization-designer-button');
  const findInstrumentationDetailsDropdown = () =>
    wrapper.findByTestId('intrumentation-details-dropdown');
  const findKeyInputAt = (index) => wrapper.findAllComponents(AnalyticsClipboardInput).at(index);

  const NUMBER_OF_CUSTOM_DASHBOARDS = 1;
  const NUMBER_OF_DASHBOARDS = jsonList.productAnalytics.length + NUMBER_OF_CUSTOM_DASHBOARDS;

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

    it('renders a list item for each custom dashboard', () => {
      expect(getCustomDashboards).toHaveBeenCalledWith(TEST_CUSTOM_DASHBOARDS_PROJECT);

      expect(findListItems()).toHaveLength(NUMBER_OF_CUSTOM_DASHBOARDS);

      expect(findListItems().at(0).props('dashboard')).toMatchObject({
        id: 'new_dashboard',
        title: 'new_dashboard',
      });
    });

    it('does not render any feature dashboards', () => {
      expect(findListItems()).toHaveLength(1);
    });
  });

  describe('when the feature dashboards are enabled', () => {
    const FEATURE = 'productAnalytics';

    beforeEach(() => {
      createWrapper({ features: [FEATURE] });
    });

    it('renders a list item for each dashboard', () => {
      expect(findListItems()).toHaveLength(NUMBER_OF_DASHBOARDS);
    });

    it('renders a list item for each feature dashboard at the start of the list', () => {
      jsonList[FEATURE].forEach((dashboard, idx) => {
        expect(findListItems().at(idx).props('dashboard')).toEqual(dashboard);
      });
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
