import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsDashboardList from 'ee/product_analytics/dashboards/components/analytics_dashboard_list.vue';
import jsonList from 'ee/product_analytics/dashboards/gl_dashboards/analytics_dashboards.json';

describe('AnalyticsDashboardList', () => {
  let wrapper;

  const findRouterDescriptions = () => wrapper.findAllByTestId('dashboard-description');
  const findRouterLinks = () => wrapper.findAllByTestId('dashboard-link');
  const findRouterIcons = () => wrapper.findAllByTestId('dashboard-icon');
  const findRouterLabels = () => wrapper.findAllByTestId('dashboard-label');

  const NUMBER_OF_DASHBOARDS = jsonList.internalDashboards.length;

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsDashboardList, {
      stubs: {
        RouterLink: true,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render titles', () => {
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterLinks().at(0).element.innerText).toContain('Overview');
    });

    it('should render descriptions', () => {
      expect(findRouterDescriptions()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterDescriptions().at(0).element.innerText).toContain('All');
    });

    it('should render links', () => {
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
    });

    it('should render icons', () => {
      expect(findRouterIcons()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterIcons().at(0).props('name')).toBe('dashboard');
    });

    it('should render label', () => {
      expect(findRouterLabels()).toHaveLength(1);
      expect(findRouterLabels().at(0).props('title')).toBe('Audience');
    });
  });
});
