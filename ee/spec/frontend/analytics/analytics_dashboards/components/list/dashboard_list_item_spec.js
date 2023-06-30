import { GlAvatar, GlIcon, GlLabel } from '@gitlab/ui';
import DashboardListItem from 'ee/analytics/analytics_dashboards/components/list/dashboard_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { I18N_BUILT_IN_DASHBOARD_LABEL } from 'ee/analytics/analytics_dashboards/constants';
import { TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE } from '../../mock_data';

jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api');

const {
  nodes,
} = TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data.project.productAnalyticsDashboards;
const USER_DEFINED_DASHBOARD = nodes.find((dashboard) => dashboard.userDefined);
const BUILT_IN_DASHBOARD = nodes.find((dashboard) => !dashboard.userDefined);

describe('DashboardsListItem', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLabel = () => wrapper.findComponent(GlLabel);
  const findListItem = () => wrapper.findByTestId('dashboard-list-item');
  const findRouterLink = () => wrapper.findByTestId('dashboard-link');
  const findDescription = () => wrapper.findByTestId('dashboard-description');

  const $router = {
    push: jest.fn(),
  };

  const createWrapper = (dashboard, props = {}) => {
    wrapper = shallowMountExtended(DashboardListItem, {
      propsData: {
        dashboard,
        ...props,
      },
      stubs: {
        RouterLink: true,
      },
      mocks: {
        $router,
      },
    });
  };

  describe('by default', () => {
    beforeEach(() => {
      createWrapper(USER_DEFINED_DASHBOARD);
    });

    it('renders the dashboard title', () => {
      expect(findRouterLink().text()).toContain(USER_DEFINED_DASHBOARD.title);
    });

    it('renders the dashboard description', () => {
      expect(findDescription().text()).toContain(USER_DEFINED_DASHBOARD.description);
    });

    it('renders the dashboard icon', () => {
      expect(findIcon().props()).toMatchObject({
        name: 'project',
        size: 16,
      });
    });

    it('renders the dashboard avatar', () => {
      expect(findAvatar().props()).toMatchObject({
        entityName: USER_DEFINED_DASHBOARD.title,
        size: 32,
      });
    });

    it('does not render the built in label', () => {
      expect(findLabel().exists()).toBe(false);
    });

    it('routes to the dashboard when a list item is clicked', async () => {
      await findListItem().trigger('click');

      expect($router.push).toHaveBeenCalledWith(USER_DEFINED_DASHBOARD.slug);
    });
  });

  describe('with a built in dashboard', () => {
    beforeEach(() => {
      createWrapper(BUILT_IN_DASHBOARD);
    });

    it('renders the dashboard label', () => {
      expect(findLabel().props('title')).toBe(I18N_BUILT_IN_DASHBOARD_LABEL);
    });
  });
});
