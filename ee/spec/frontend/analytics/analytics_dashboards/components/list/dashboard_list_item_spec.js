import { GlAvatar, GlIcon, GlLabel } from '@gitlab/ui';
import DashboardListItem from 'ee/analytics/analytics_dashboards/components/list/dashboard_list_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import jsonList from 'ee/analytics/analytics_dashboards/gl_dashboards/analytics_dashboards.json';

jest.mock('ee/analytics/analytics_dashboards/api/dashboards_api');

const DASHBOARD = jsonList.productAnalytics[0];

describe('DashboardsList', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findListItem = () => wrapper.findByTestId('dashboard-list-item');
  const findRouterLink = () => wrapper.findByTestId('dashboard-link');
  const findDescription = () => wrapper.findByTestId('dashboard-description');

  const $router = {
    push: jest.fn(),
  };

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(DashboardListItem, {
      propsData: {
        dashboard: DASHBOARD,
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

  beforeEach(() => {
    createWrapper();
  });

  it('renders the dashboard title', () => {
    expect(findRouterLink().text()).toContain(DASHBOARD.title);
  });

  it('renders the dashboard description', () => {
    expect(findDescription().text()).toContain(DASHBOARD.description);
  });

  it('renders the dashboard icon', () => {
    expect(findIcon().props()).toMatchObject({
      name: 'project',
      size: 16,
    });
  });

  it('renders the dashboard avatar', () => {
    expect(findAvatar().props()).toMatchObject({
      entityName: DASHBOARD.title,
      size: 32,
    });
  });

  it('renders the dashboard label', () => {
    DASHBOARD.labels.forEach((label, idx) => {
      expect(findLabels().at(idx).props('title')).toBe(label);
    });
  });

  it('routes to the dashboard when a list item is clicked', async () => {
    await findListItem().trigger('click');

    expect($router.push).toHaveBeenCalledWith(DASHBOARD.id);
  });
});
