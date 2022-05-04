import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlButton, GlLoadingIcon } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { pushEECproductAddToCartEvent } from '~/google_tag_manager';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import PipelineUsageApp from 'ee/usage_quotas/pipelines/components/app.vue';
import ProjectList from 'ee/usage_quotas/pipelines/components/project_list.vue';
import { LABEL_BUY_ADDITIONAL_MINUTES, ERROR_MESSAGE } from 'ee/usage_quotas/pipelines/constants';
import getNamespaceProjectsInfo from 'ee/usage_quotas/pipelines/queries/namespace_projects_info.query.graphql';
import getCiMinutesUsageNamespace from 'ee/usage_quotas/ci_minutes_usage/graphql/queries/ci_minutes_namespace.query.graphql';
import {
  defaultProvide,
  mockGetNamespaceProjectsInfo,
  mockGetCiMinutesUsageNamespace,
} from '../mock_data';

Vue.use(VueApollo);
jest.mock('~/google_tag_manager');

describe('PipelineUsageApp', () => {
  let wrapper;

  const createMockApolloProvider = ({
    reject = false,
    mockNamespaceProject = mockGetNamespaceProjectsInfo,
    mockCiMinutesUsageQuery = mockGetCiMinutesUsageNamespace,
  } = {}) => {
    const rejectResponse = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    const requestHandlers = [
      [
        getNamespaceProjectsInfo,
        reject ? rejectResponse : jest.fn().mockResolvedValue(mockNamespaceProject),
      ],
      [
        getCiMinutesUsageNamespace,
        reject ? rejectResponse : jest.fn().mockResolvedValue(mockCiMinutesUsageQuery),
      ],
    ];

    return createMockApollo(requestHandlers);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findBuyAdditionalMinutesButton = () => wrapper.findComponent(GlButton);

  const createComponent = ({ provide = {}, mockApollo } = {}) => {
    wrapper = shallowMountExtended(PipelineUsageApp, {
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlButton,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Buy additional minutes Button', () => {
    const mockApollo = createMockApolloProvider();

    it('calls pushEECproductAddToCartEvent on click', () => {
      createComponent({ mockApollo });
      findBuyAdditionalMinutesButton().trigger('click');
      expect(pushEECproductAddToCartEvent).toHaveBeenCalledTimes(1);
    });

    describe('Gitlab SaaS: valid data for buyAdditionalMinutesPath and buyAdditionalMinutesTarget', () => {
      it('renders the button to buy additional minutes', () => {
        createComponent({ mockApollo });
        expect(findBuyAdditionalMinutesButton().exists()).toBe(true);
        expect(findBuyAdditionalMinutesButton().text()).toBe(LABEL_BUY_ADDITIONAL_MINUTES);
      });
    });

    describe('Gitlab Self-Managed: buyAdditionalMinutesPath and buyAdditionalMinutesTarget not provided', () => {
      beforeEach(() => {
        createComponent({
          mockApollo,
          provide: {
            buyAdditionalMinutesPath: undefined,
            buyAdditionalMinutesTarget: undefined,
          },
        });
      });

      it('does not render the button to buy additional minutes', () => {
        expect(findBuyAdditionalMinutesButton().exists()).toBe(false);
      });
    });
  });

  describe('with apollo fetching successful', () => {
    beforeEach(() => {
      const mockCiMinutesUsageQuery = { ...mockGetCiMinutesUsageNamespace };
      mockCiMinutesUsageQuery.data.ciMinutesUsage.nodes[0].monthIso8601 = formatDate(
        Date.now(),
        'yyyy-mm-dd',
      );

      const mockApollo = createMockApolloProvider({
        mockCiMinutesUsageQuery,
      });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('passes the correct props to ProjectList', () => {
      expect(findProjectList().props()).toMatchObject({
        pageInfo: {
          endCursor: 'eyJpZCI6IjYifQ',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: 'eyJpZCI6IjYifQ',
        },
        projects: [
          {
            ci_minutes: mockGetCiMinutesUsageNamespace.data.ciMinutesUsage.nodes[0].minutes,
            project: {
              avatarUrl: null,
              fullPath: 'flightjs/Flight',
              id: 'gid://gitlab/Project/6',
              name: 'Flight',
              nameWithNamespace: 'Flightjs / Flight',
              webUrl: 'http://gdk.test:3000/flightjs/Flight',
            },
          },
        ],
      });
    });
  });

  describe('with apollo loading', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider({
        mockCiMinutesUsageQuery: new Promise(() => {}),
      });
      createComponent({ mockApollo });
    });

    it('should show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('with apollo fetching error', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider({ reject: true });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('renders failed request error message', () => {
      expect(findAlert().text()).toBe(ERROR_MESSAGE);
    });
  });

  describe('with a namespace without projects', () => {
    beforeEach(() => {
      const mockNamespaceProject = { ...mockGetNamespaceProjectsInfo };
      mockNamespaceProject.data.namespace.projects.nodes = [];

      const mockApollo = createMockApolloProvider({
        mockNamespaceProject,
      });
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('passes an empty array as projects to ProjectList', () => {
      expect(findProjectList().props('projects')).toEqual([]);
    });
  });

  describe('apollo calls', () => {
    beforeEach(() => {
      const mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
      return waitForPromises();
    });

    it('makes a query to fetch more data when `fetchMore` is emitted', async () => {
      jest
        .spyOn(wrapper.vm.$apollo.queries.namespace, 'fetchMore')
        .mockImplementation(jest.fn().mockResolvedValue());

      findProjectList().vm.$emit('fetchMore');
      await nextTick();

      expect(wrapper.vm.$apollo.queries.namespace.fetchMore).toHaveBeenCalledTimes(1);
    });
  });
});
