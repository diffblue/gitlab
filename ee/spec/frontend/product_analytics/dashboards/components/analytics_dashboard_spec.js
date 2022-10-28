import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AnalyticsDashboard from 'ee/product_analytics/dashboards/components/analytics_dashboard.vue';
import CustomizableDashboard from 'ee/vue_shared/components/customizable_dashboard/customizable_dashboard.vue';
import { dashboard } from 'ee_jest/vue_shared/components/customizable_dashboard/mock_data';

describe('AnalyticsDashboard', () => {
  let wrapper;

  const findDashboard = () => wrapper.findComponent(CustomizableDashboard);

  const createWrapper = (data = {}, routeId) => {
    const mocks = {
      $route: {
        params: {
          id: routeId || '',
        },
      },
      $router: {
        replace() {},
        push() {},
      },
    };

    wrapper = shallowMountExtended(AnalyticsDashboard, {
      data() {
        return {
          dashboard: null,
          ...data,
        };
      },
      stubs: ['router-link', 'router-view'],
      mocks,
    });
  };

  describe('when mounted', () => {
    it('should render with mock dashboard', () => {
      createWrapper({
        dashboard,
      });

      expect(findDashboard().props()).toStrictEqual({
        widgets: dashboard.widgets,
        editable: false,
      });
    });

    it('should render overview dashboard by id', async () => {
      createWrapper({}, 'dashboard_overview');

      await waitForPromises();

      expect(findDashboard().exists()).toBe(true);
    });

    it('should render audience dashboard by id', async () => {
      createWrapper({}, 'dashboard_audience');

      await waitForPromises();

      expect(findDashboard().exists()).toBe(true);
    });
  });
});
