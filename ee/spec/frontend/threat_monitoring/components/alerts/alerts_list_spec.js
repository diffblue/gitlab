import { GlIntersectionObserver, GlSkeletonLoading } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import AlertFilters from 'ee/threat_monitoring/components/alerts/alert_filters.vue';
import AlertStatus from 'ee/threat_monitoring/components/alerts/alert_status.vue';
import AlertsList from 'ee/threat_monitoring/components/alerts/alerts_list.vue';
import { DEFAULT_FILTERS } from 'ee/threat_monitoring/components/alerts/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getAlertsQuery from '~/graphql_shared/queries/get_alerts.query.graphql';
import {
  getAlertsQuerySpy,
  emptyGetAlertsQuerySpy,
  loadingQuerySpy,
} from '../../mocks/mock_apollo';
import { mockAlerts, mockPageInfo } from '../../mocks/mock_data';

let localVue;

describe('AlertsList component', () => {
  let wrapper;
  const refetchSpy = jest.fn();
  const DEFAULT_PROJECT_PATH = '#';
  const DEFAULT_SORT = 'STARTED_AT_DESC';
  const PAGE_SIZE = 20;
  const defaultProps = { filters: DEFAULT_FILTERS };
  let querySpy;

  const createMockApolloProvider = (query) => {
    localVue.use(VueApollo);
    return createMockApollo([[getAlertsQuery, query]]);
  };

  const shallowApolloMock = {
    queries: {
      alerts: {
        fetchMore: jest.fn().mockResolvedValue(),
        loading: false,
        refetch: refetchSpy,
      },
    },
  };

  const findAlertFilters = () => wrapper.findComponent(AlertFilters);
  const findAssigneeColumn = () => wrapper.findByTestId('threat-alerts-assignee');
  const findAssigneeColumnAt = (id) => wrapper.findAllByTestId('threat-alerts-assignee').at(id);
  const findUnconfiguredAlert = () => wrapper.findByTestId('threat-alerts-unconfigured');
  const findErrorAlert = () => wrapper.findByTestId('threat-alerts-error');
  const findStartedAtColumn = () => wrapper.findByTestId('threat-alerts-started-at');
  const findStartedAtColumnHeader = () => wrapper.findByTestId('threat-alerts-started-at-header');
  const findIdColumn = () => wrapper.findByTestId('threat-alerts-id');
  const findEventCountColumn = () => wrapper.findByTestId('threat-alerts-event-count');
  const findIssueColumn = () => wrapper.findByTestId('threat-alerts-issue');
  const findIssueColumnAt = (id) => wrapper.findAllByTestId('threat-alerts-issue').at(id);
  const findStatusColumn = () => wrapper.findComponent(AlertStatus);
  const findStatusColumnHeader = () => wrapper.findByTestId('threat-alerts-status-header');
  const findEmptyState = () => wrapper.findByTestId('threat-alerts-empty-state');
  const findGlIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findGlSkeletonLoading = () => wrapper.findComponent(GlSkeletonLoading);

  const createWrapper = ({ $apollo, apolloSpy = getAlertsQuerySpy, data, stubs = {} } = {}) => {
    let apolloOptions;
    if ($apollo) {
      apolloOptions = {
        mocks: {
          $apollo,
        },
        data,
      };
    } else {
      localVue = createLocalVue();
      querySpy = apolloSpy;
      const mockApollo = createMockApolloProvider(querySpy);
      apolloOptions = {
        localVue,
        apolloProvider: mockApollo,
      };
    }

    wrapper = mountExtended(AlertsList, {
      propsData: defaultProps,
      provide: {
        documentationPath: '#',
        projectPath: DEFAULT_PROJECT_PATH,
      },
      stubs: {
        AlertDrawer: true,
        AlertStatus: true,
        AlertFilters: true,
        GlAlert: true,
        GlLoadingIcon: true,
        GlIntersectionObserver: true,
        ...stubs,
      },
      ...apolloOptions,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(async () => {
      createWrapper();
      await waitForPromises();
    });

    it('shows threat monitoring alert filters', () => {
      expect(findAlertFilters().exists()).toBe(true);
      expect(findAlertFilters().props('filters')).toBe(DEFAULT_FILTERS);
    });

    it('does have the default filters initially', () => {
      expect(querySpy).toHaveBeenCalledTimes(1);
      expect(querySpy).toHaveBeenCalledWith(
        expect.objectContaining({
          firstPageSize: PAGE_SIZE,
          projectPath: DEFAULT_PROJECT_PATH,
          sort: DEFAULT_SORT,
          ...DEFAULT_FILTERS,
        }),
      );
    });

    it('does update its filters on filter event emitted', async () => {
      const newFilters = { statuses: [] };
      expect(wrapper.vm.filters).toEqual(DEFAULT_FILTERS);
      findAlertFilters().vm.$emit('filter-change', newFilters);
      await nextTick();
      expect(wrapper.vm.filters).toEqual(newFilters);
    });

    it.each`
      column          | findColumn
      ${'startedAt'}  | ${findStartedAtColumn}
      ${'id'}         | ${findIdColumn}
      ${'eventCount'} | ${findEventCountColumn}
      ${'issue'}      | ${findIssueColumn}
      ${'assignee'}   | ${findAssigneeColumn}
      ${'status'}     | ${findStatusColumn}
    `('does show the $column column', ({ findColumn }) => {
      expect(findColumn().exists()).toBe(true);
    });

    it('does not show the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('does not show the unconfigured alert error state when the list is populated', () => {
      expect(findUnconfiguredAlert().exists()).toBe(false);
    });

    it('does not show the request error state', () => {
      expect(findErrorAlert().exists()).toBe(false);
    });

    it('does show the observer component', () => {
      expect(findGlIntersectionObserver().exists()).toBe(true);
    });

    it('does initially sort by started at, descending', () => {
      expect(wrapper.vm.sort).toBe('STARTED_AT_DESC');
      expect(findStartedAtColumnHeader().attributes('aria-sort')).toBe('descending');
    });

    it('updates sort with new direction and column key', async () => {
      expect(findStatusColumnHeader().attributes('aria-sort')).toBe('none');

      findStatusColumnHeader().trigger('click');
      await nextTick();

      expect(wrapper.vm.sort).toBe('STATUS_DESC');
      expect(findStatusColumnHeader().attributes('aria-sort')).toBe('descending');

      findStatusColumnHeader().trigger('click');
      await nextTick();

      expect(wrapper.vm.sort).toBe('STATUS_ASC');
      expect(findStatusColumnHeader().attributes('aria-sort')).toBe('ascending');
    });

    it('navigates to the alert details page on title click', () => {
      expect(findIdColumn().attributes('href')).toBe('/alerts/01');
    });

    describe('issue column', () => {
      it('displays a "-" for an alert without an issue', () => {
        expect(findIssueColumnAt(3).text()).toBe('-');
      });

      it.each`
        description                                 | id   | text             | link
        ${'when an issue is created and is open'}   | ${0} | ${'#5'}          | ${mockAlerts[0].issue.webUrl}
        ${'when an issue is created and is closed'} | ${1} | ${'#6 (closed)'} | ${mockAlerts[1].issue.webUrl}
      `('displays the correct text $description', ({ id, text, link }) => {
        expect(findIssueColumnAt(id).text()).toBe(text);
        expect(findIssueColumnAt(id).find('a').attributes('href')).toBe(link);
      });
    });

    describe('assignee column', () => {
      it('displays an avatar for an alert with an assignee', () => {
        const index = 0;
        const { name, avatarUrl, webUrl } = mockAlerts[index].assignees.nodes[0];
        expect(findAssigneeColumnAt(index).find('a')).toBeDefined();
        expect(findAssigneeColumnAt(index).find('a').attributes()).toMatchObject({
          href: webUrl,
          target: '_blank',
          title: name,
        });
        expect(findAssigneeColumnAt(index).find('img')).toBeDefined();
        expect(findAssigneeColumnAt(index).find('img').attributes()).toMatchObject({
          src: avatarUrl,
          label: name,
        });
      });

      it('displays a "-" for an unassigned alert', () => {
        expect(findAssigneeColumnAt(1).text()).toBe('-');
      });
    });
  });

  describe('empty state', () => {
    beforeEach(async () => {
      createWrapper({ apolloSpy: emptyGetAlertsQuerySpy });
      await waitForPromises();
    });

    it('does show the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does show the unconfigured alert error state when the list is empty', () => {
      expect(findUnconfiguredAlert().exists()).toBe(true);
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      createWrapper({ apolloSpy: loadingQuerySpy });
    });

    it('does show the loading state', () => {
      expect(findGlSkeletonLoading().exists()).toBe(true);
    });

    it('does not show all columns', () => {
      expect(findStartedAtColumn().exists()).toBe(false);
      expect(findIdColumn().exists()).toBe(false);
      expect(findStatusColumn().exists()).toBe(false);
    });

    it('does not show the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('error state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('does not show the unconfigured alert error state when there is a request error', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        errored: true,
      });
      await nextTick();
      expect(findErrorAlert().exists()).toBe(true);
      expect(findUnconfiguredAlert().exists()).toBe(false);
    });

    it('does not show the unconfigured alert error state when there is a request error that has been dismissed', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        isErrorAlertDismissed: true,
      });
      await nextTick();
      expect(findUnconfiguredAlert().exists()).toBe(false);
    });
  });

  describe('loading more alerts', () => {
    it('does request more data', async () => {
      createWrapper({
        $apollo: shallowApolloMock,
        data: () => ({
          alerts: mockAlerts,
          pageInfo: mockPageInfo,
        }),
      });
      findGlIntersectionObserver().vm.$emit('appear');
      await nextTick();
      expect(wrapper.vm.$apollo.queries.alerts.fetchMore).toHaveBeenCalledTimes(1);
    });
  });

  describe('changing alert status', () => {
    beforeEach(() => {
      createWrapper({
        $apollo: shallowApolloMock,
        data: () => ({
          alerts: mockAlerts,
          pageInfo: mockPageInfo,
        }),
      });
    });

    it('does refetch the alerts when an alert status has changed', async () => {
      expect(refetchSpy).toHaveBeenCalledTimes(0);
      findStatusColumn().vm.$emit('alert-update');
      await nextTick();
      expect(refetchSpy).toHaveBeenCalledTimes(1);
    });

    it('does show an error if changing an alert status fails', async () => {
      const error = 'Error.';
      expect(findErrorAlert().exists()).toBe(false);
      findStatusColumn().vm.$emit('alert-error', error);
      await nextTick();
      expect(findErrorAlert().exists()).toBe(true);
      expect(findErrorAlert().text()).toBe(error);
    });
  });
});
