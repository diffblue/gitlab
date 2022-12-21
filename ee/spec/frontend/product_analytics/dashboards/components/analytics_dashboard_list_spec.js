import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AnalyticsDashboardList from 'ee/product_analytics/dashboards/components/analytics_dashboard_list.vue';
import { I18N_DASHBOARD_LIST } from 'ee/product_analytics/dashboards/constants';
import jsonList from 'ee/product_analytics/dashboards/gl_dashboards/analytics_dashboards.json';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('AnalyticsDashboardList', () => {
  let wrapper;

  const findRouterDescriptions = () => wrapper.findAllByTestId('dashboard-description');
  const findRouterLinks = () => wrapper.findAllByTestId('dashboard-link');
  const findRouterIcons = () => wrapper.findAllByTestId('dashboard-icon');
  const findRouterLabels = () => wrapper.findAllByTestId('dashboard-label');
  const findListItems = () => wrapper.findAllByTestId('dashboard-list-item');
  const findPageTitle = () => wrapper.findByTestId('title');
  const findPageDescription = () => wrapper.findByTestId('description');
  const findHelpLink = () => wrapper.findByTestId('help-link');

  const NUMBER_OF_DASHBOARDS = jsonList.internalDashboards.length;

  const $router = {
    push: jest.fn(),
  };

  const createWrapper = () => {
    wrapper = shallowMountExtended(AnalyticsDashboardList, {
      stubs: {
        RouterLink: true,
      },
      mocks: {
        $router,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the page title', () => {
      expect(findPageTitle().text()).toBe(I18N_DASHBOARD_LIST.title);
    });

    it('should render the page description', () => {
      expect(findPageDescription().text()).toContain(I18N_DASHBOARD_LIST.description);
    });

    it('should render the help link', () => {
      expect(findHelpLink().text()).toBe(I18N_DASHBOARD_LIST.learnMore);
      expect(findHelpLink().attributes('href')).toBe(
        helpPagePath('user/product_analytics/index', {
          anchor: 'product-analytics-dashboards',
        }),
      );
    });

    it('should render titles', () => {
      expect(findRouterLinks()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterLinks().at(0).element.innerText).toContain('Audience');
    });

    it('should render descriptions', () => {
      expect(findRouterDescriptions()).toHaveLength(NUMBER_OF_DASHBOARDS);
      expect(findRouterDescriptions().at(0).element.innerText).toContain(
        'Understand your audience',
      );
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
});
