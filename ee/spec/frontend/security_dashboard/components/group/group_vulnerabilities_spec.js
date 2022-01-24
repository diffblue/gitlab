import { GlAlert, GlIntersectionObserver, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import GroupVulnerabilities from 'ee/security_dashboard/components/group/group_vulnerabilities.vue';
import VulnerabilityList from 'ee/security_dashboard/components/shared/vulnerability_list.vue';
import vulnerabilitiesQuery from 'ee/security_dashboard/graphql/queries/group_vulnerabilities.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { generateVulnerabilities } from '../mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Group Security Dashboard Vulnerabilities Component', () => {
  let wrapper;
  const apolloMock = {
    queries: { vulnerabilities: { loading: true } },
  };

  const groupFullPath = 'group-full-path';

  const findIntersectionObserver = () => wrapper.findComponent(GlIntersectionObserver);
  const findVulnerabilities = () => wrapper.findComponent(VulnerabilityList);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const expectLoadingState = ({ initial = false, nextPage = false }) => {
    expect(findVulnerabilities().props('isLoading')).toBe(initial);
    expect(findLoadingIcon().exists()).toBe(nextPage);
  };

  const createWrapper = ({ $apollo = apolloMock } = {}) => {
    return shallowMount(GroupVulnerabilities, {
      mocks: {
        $apollo,
        fetchNextPage: () => {},
      },
      propsData: {
        filters: {},
      },
      provide: {
        groupFullPath,
        hasVulnerabilities: true,
        hasJiraVulnerabilitiesIntegrationEnabled: false,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the query is loading', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: true } },
        },
      });
    });

    it('shows the initial loading state', () => {
      expectLoadingState({ initial: true });
    });
  });

  describe('when the query returned an error status', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        errorLoadingVulnerabilities: true,
      });
    });

    it('displays the alert', () => {
      expect(findAlert().text()).toBe(
        'Error fetching the vulnerability list. Please check your network connection and try again.',
      );
    });

    it('should have an alert that is dismissable', () => {
      const alert = findAlert();
      alert.vm.$emit('dismiss');
      return wrapper.vm.$nextTick(() => {
        expect(alert.exists()).toBe(false);
      });
    });

    it('does not display the vulnerabilities', () => {
      expect(findVulnerabilities().exists()).toBe(false);
    });
  });

  describe('when the query is loaded and we have results', () => {
    const vulnerabilities = generateVulnerabilities();

    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        vulnerabilities,
      });
    });

    it('passes down properties correctly', () => {
      expect(findVulnerabilities().props()).toEqual({
        filters: {},
        isLoading: false,
        shouldShowProjectNamespace: true,
        vulnerabilities,
      });
    });

    it('defaults to severity column for sorting', () => {
      expect(wrapper.vm.sortBy).toBe('severity');
    });

    it('defaults to desc as sorting direction', () => {
      expect(wrapper.vm.sortDirection).toBe('desc');
    });

    it('handles sorting', () => {
      findVulnerabilities().vm.$listeners['sort-changed']({
        sortBy: 'description',
        sortDesc: false,
      });
      expect(wrapper.vm.sortBy).toBe('description');
      expect(wrapper.vm.sortDirection).toBe('asc');
    });

    it('does not show loading any state', () => {
      expectLoadingState({ initial: false, nextPage: false });
    });
  });

  describe('when there is more than a page of vulnerabilities', () => {
    const vulnerabilities = generateVulnerabilities();

    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: false } },
        },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        vulnerabilities,
        pageInfo: {
          hasNextPage: true,
        },
      });
    });

    it('should render the observer component', () => {
      expect(findIntersectionObserver().exists()).toBe(true);
    });
  });

  describe('when the query is loading the next page', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        $apollo: {
          queries: { vulnerabilities: { loading: true } },
        },
      });

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        vulnerabilities: generateVulnerabilities(),
        pageInfo: {
          hasNextPage: true,
        },
      });
    });

    it('should render the loading spinner', () => {
      expectLoadingState({ nextPage: true });
    });
  });

  describe('when filter or sort is changed', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should show the initial loading state when the filter is changed', () => {
      wrapper.setProps({ filter: {} });

      expectLoadingState({ initial: true });
    });

    it('should show the initial loading state when the sort is changed', () => {
      findVulnerabilities().vm.$emit('sort-changed', {
        sortBy: 'description',
        sortDesc: false,
      });

      expectLoadingState({ initial: true });
    });
  });

  describe('filters prop', () => {
    const mockQuery = jest.fn().mockResolvedValue({
      data: {
        group: {
          id: 'group-1',
          vulnerabilities: {
            nodes: [],
            pageInfo: { endCursor: '', hasNextPage: '' },
          },
        },
      },
    });

    const createWrapperWithApollo = ({ query, filters }) => {
      wrapper = shallowMount(GroupVulnerabilities, {
        localVue,
        apolloProvider: createMockApollo([[vulnerabilitiesQuery, query]]),
        propsData: { filters },
        provide: { groupFullPath: 'path' },
      });
    };

    it('does not run the query when filters is null', () => {
      createWrapperWithApollo({ query: mockQuery, filters: null });

      expect(mockQuery).not.toHaveBeenCalled();
    });

    it('runs query when filters is an object', () => {
      createWrapperWithApollo({ query: mockQuery, filters: {} });

      expect(mockQuery).toHaveBeenCalled();
    });
  });
});
