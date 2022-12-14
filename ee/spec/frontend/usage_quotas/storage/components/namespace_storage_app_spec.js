import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import NamespaceStorageApp from 'ee/usage_quotas/storage/components/namespace_storage_app.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import getNamespaceStorageQuery from 'ee/usage_quotas/storage/queries/namespace_storage.query.graphql';
import getDependencyProxyTotalSizeQuery from 'ee/usage_quotas/storage/queries/dependency_proxy_usage.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { formatUsageSize } from 'ee/usage_quotas/storage/utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import UsageGraph from 'ee/usage_quotas/storage/components/usage_graph.vue';
import UsageStatistics from 'ee/usage_quotas/storage/components/usage_statistics.vue';
import StorageUsageStatistics from 'ee/usage_quotas/storage/components/storage_usage_statistics.vue';
import StorageInlineAlert from 'ee/usage_quotas/storage/components/storage_inline_alert.vue';
import DependencyProxyUsage from 'ee/usage_quotas/storage/components/dependency_proxy_usage.vue';
import ContainerRegistryUsage from 'ee/usage_quotas/storage/components/container_registry_usage.vue';
import {
  defaultNamespaceProvideValues,
  mockedNamespaceStorageResponse,
  mockDependencyProxyResponse,
} from '../mock_data';

const TEST_LIMIT = 1000;

jest.mock('~/flash');
jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('NamespaceStorageApp', () => {
  let wrapper;

  function createMockApolloProvider(response = mockedNamespaceStorageResponse) {
    const successHandler = jest.fn().mockResolvedValue(response);
    const requestHandlers = [
      [getNamespaceStorageQuery, successHandler],
      [getDependencyProxyTotalSizeQuery, jest.fn().mockResolvedValue(mockDependencyProxyResponse)],
    ];

    return createMockApollo(requestHandlers);
  }

  function createPendingMockApolloProvider() {
    const successHandler = new Promise(() => {});
    const requestHandlers = [
      [getNamespaceStorageQuery, successHandler],
      [getDependencyProxyTotalSizeQuery, jest.fn().mockResolvedValue(mockDependencyProxyResponse)],
    ];

    return createMockApollo(requestHandlers);
  }

  function createFailedMockApolloProvider() {
    const failedHandler = jest.fn().mockRejectedValue(new Error('Network error!'));
    const requestHandlers = [
      [getNamespaceStorageQuery, failedHandler],
      [getDependencyProxyTotalSizeQuery, jest.fn().mockResolvedValue(mockDependencyProxyResponse)],
    ];

    return createMockApollo(requestHandlers);
  }

  const findTotalUsage = () => wrapper.findByTestId('total-usage');
  const findUsageGraph = () => wrapper.findComponent(UsageGraph);
  const findUsageStatistics = () => wrapper.findComponent(UsageStatistics);
  const findStorageInlineAlert = () => wrapper.findComponent(StorageInlineAlert);
  const findPurchaseStorageLink = () => wrapper.find("[data-testid='purchase-storage-link']");
  const findDependencyProxy = () => wrapper.findComponent(DependencyProxyUsage);
  const findStorageUsageStatistics = () => wrapper.findComponent(StorageUsageStatistics);
  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findPrevButton = () => wrapper.find('[data-testid="prevButton"]');
  const findNextButton = () => wrapper.find('[data-testid="nextButton"]');
  const findContainerRegistry = () => wrapper.findComponent(ContainerRegistryUsage);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = ({
    provide = {},
    storageLimitEnforced = false,
    additionalRepoStorageByNamespace = false,
    dependencyProxyTotalSize = '',
    isFreeNamespace = false,
    mockApollo = {},
    isPersonalNamespace = false,
  } = {}) => {
    wrapper = mountExtended(NamespaceStorageApp, {
      apolloProvider: mockApollo,
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
      propsData: {
        storageLimitEnforced,
        isAdditionalStorageFlagEnabled: additionalRepoStorageByNamespace,
        isFreeNamespace,
        isPersonalNamespace,
      },
      data() {
        return {
          dependencyProxyTotalSize,
        };
      },
    });
  };

  let mockApollo;

  describe('project list', () => {
    beforeEach(async () => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders the 2 projects', () => {
      expect(wrapper.findComponent(ProjectList).props('projects')).toHaveLength(2);
    });
  });

  describe('size limit', () => {
    it('does not render limit information when storageSizeLimit is 0', async () => {
      const namespaceWithZeroLimit = { ...mockedNamespaceStorageResponse };
      namespaceWithZeroLimit.data.namespace.storageSizeLimit = 0;
      mockApollo = createMockApolloProvider(namespaceWithZeroLimit);
      createComponent({ mockApollo });
      await waitForPromises();

      expect(wrapper.text()).not.toContain(formatUsageSize(0));
    });

    it('renders limit information when storageSizeLimit is set to other numbers', async () => {
      const namespaceWithLimit = { ...mockedNamespaceStorageResponse };
      namespaceWithLimit.data.namespace.storageSizeLimit = TEST_LIMIT;
      mockApollo = createMockApolloProvider(namespaceWithLimit);
      createComponent({ mockApollo });
      await waitForPromises();

      expect(wrapper.text()).toContain(
        formatUsageSize(namespaceWithLimit.data.namespace.storageSizeLimit),
      );
    });
  });

  describe('purchase storage link', () => {
    it('does not render an additional link when purchaseStorageUrl is not set', async () => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
      await waitForPromises();

      expect(findPurchaseStorageLink().exists()).toBe(false);
    });

    it('does render link when purchaseStorageUrl is set', async () => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo, provide: { purchaseStorageUrl: 'customers.gitlab.com' } });
      await waitForPromises();

      const link = findPurchaseStorageLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('customers.gitlab.com');
    });
  });

  describe('Dependency proxy usage', () => {
    beforeEach(async () => {
      mockApollo = createMockApolloProvider();
    });

    it('shows the dependency proxy usage component', async () => {
      createComponent({
        mockApollo,
        additionalRepoStorageByNamespace: true,
        dependencyProxyTotalSize: '512 bytes',
        isPersonalNamespace: false,
      });
      await waitForPromises();

      expect(findDependencyProxy().exists()).toBe(true);
    });

    it('does not display the dependency proxy for personal namespaces', () => {
      createComponent({
        mockApollo,
        additionalRepoStorageByNamespace: true,
        dependencyProxyTotalSize: '512 bytes',
        isPersonalNamespace: true,
      });

      expect(findDependencyProxy().exists()).toBe(false);
    });
  });

  describe('Container registry usage', () => {
    it('should show the container registry usage component', async () => {
      mockApollo = createMockApolloProvider();
      createComponent({
        mockApollo,
        additionalRepoStorageByNamespace: true,
        dependencyProxyTotalSize: '512 bytes',
      });
      await waitForPromises();

      expect(findContainerRegistry().exists()).toBe(true);
      expect(findContainerRegistry().props()).toEqual({
        containerRegistrySize:
          mockedNamespaceStorageResponse.data.namespace.rootStorageStatistics.containerRegistrySize,
      });
    });
  });

  describe('filtering projects', () => {
    let searchAndSortBar;
    const sampleSearchTerm = 'GitLab';

    beforeEach(() => {
      mockApollo = createMockApolloProvider();
      createComponent({
        mockApollo,
        additionalRepoStorageByNamespace: true,
      });
      searchAndSortBar = findSearchAndSortBar();
    });

    it('triggers search if user enters search input', () => {
      expect(wrapper.vm.searchTerm).toBe('');

      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);

      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);
    });

    it('triggers search if user clears the entered search input', () => {
      searchAndSortBar.vm.$emit('onFilter', sampleSearchTerm);
      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);

      searchAndSortBar.vm.$emit('onFilter', '');
      expect(wrapper.vm.searchTerm).toBe('');
    });

    it('triggers search with empty string if user enters short search input', () => {
      searchAndSortBar.vm.$emit('onFilter', sampleSearchTerm);
      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);

      const sampleShortSearchTerm = 'Gi';
      findSearchAndSortBar().vm.$emit('onFilter', sampleShortSearchTerm);
      expect(wrapper.vm.searchTerm).toBe('');
    });
  });

  describe('projects table pagination component', () => {
    const namespaceWithPageInfo = { ...mockedNamespaceStorageResponse };
    namespaceWithPageInfo.data.namespace.projects.pageInfo.hasNextPage = true;

    beforeEach(async () => {
      mockApollo = createMockApolloProvider(namespaceWithPageInfo);
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('has "Prev" button disabled', () => {
      expect(findPrevButton().attributes().disabled).toBe('disabled');
    });

    it('has "Next" button enabled', () => {
      expect(findNextButton().attributes().disabled).toBeUndefined();
    });

    describe('apollo calls', () => {
      beforeEach(async () => {
        namespaceWithPageInfo.data.namespace.projects.pageInfo.hasPreviousPage = true;
        namespaceWithPageInfo.data.namespace.projects.pageInfo.hasNextPage = true;
        mockApollo = createMockApolloProvider(namespaceWithPageInfo);
        createComponent({ mockApollo });

        jest
          .spyOn(wrapper.vm.$apollo.queries.namespace, 'fetchMore')
          .mockImplementation(jest.fn().mockResolvedValue({}));

        await waitForPromises();
      });

      it('contains correct `first` and `last` values when clicking "Prev" button', async () => {
        findPrevButton().trigger('click');
        expect(wrapper.vm.$apollo.queries.namespace.fetchMore).toHaveBeenCalledWith(
          expect.objectContaining({
            variables: expect.objectContaining({ first: undefined, last: expect.any(Number) }),
          }),
        );
      });

      it('contains `first` value when clicking "Next" button', () => {
        findNextButton().trigger('click');
        expect(wrapper.vm.$apollo.queries.namespace.fetchMore).toHaveBeenCalledWith(
          expect.objectContaining({
            variables: expect.objectContaining({ first: expect.any(Number) }),
          }),
        );
      });
    });

    describe('handling failed apollo requests', () => {
      beforeEach(async () => {
        mockApollo = createFailedMockApolloProvider();
        createComponent({ mockApollo });

        await waitForPromises();
      });

      it('shows gl-alert with error message', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().text()).toBe('Something went wrong while loading usage details');
      });

      it('captures the exception in Sentry', async () => {
        await Vue.nextTick();
        expect(captureException).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('new storage statistics usage design', () => {
    describe('when namespace is on free plan', () => {
      beforeEach(async () => {
        mockApollo = createMockApolloProvider();

        createComponent({
          additionalRepoStorageByNamespace: true,
          storageLimitEnforced: true,
          isFreeNamespace: true,
          mockApollo,
        });
        await waitForPromises();
      });

      it('renders the new storage design', () => {
        expect(findStorageUsageStatistics().exists()).toBe(true);
      });

      it('passes storageLimitEnforced prop correctly', () => {
        expect(findStorageUsageStatistics().props('storageLimitEnforced')).toBe(true);
      });

      it('passes storageSize as totalRepositorySize', () => {
        expect(findStorageUsageStatistics().props('totalRepositorySize')).toBe(
          mockedNamespaceStorageResponse.data.namespace.rootStorageStatistics.storageSize,
        );
      });

      describe('loading', () => {
        it.each`
          loadingError | queryLoading | expectedValue
          ${true}      | ${false}     | ${true}
          ${false}     | ${true}      | ${true}
          ${false}     | ${false}     | ${false}
        `(
          'pass loading prop as $expectedValue if loadingError is $loadingError and queryLoading is $queryLoading',
          async ({ loadingError, queryLoading, expectedValue }) => {
            // change mockApollo provider based on loadingError and queryLoading
            if (loadingError) {
              mockApollo = createFailedMockApolloProvider();
            } else if (queryLoading) {
              mockApollo = createPendingMockApolloProvider();
            } else {
              mockApollo = createMockApolloProvider();
            }

            createComponent({
              additionalRepoStorageByNamespace: true,
              storageLimitEnforced: true,
              isFreeNamespace: true,
              mockApollo,
            });

            await waitForPromises();

            expect(findStorageUsageStatistics().props('loading')).toBe(expectedValue);
          },
        );
      });
    });

    describe('when namespace is not on free plan', () => {
      beforeEach(async () => {
        createComponent({
          additionalRepoStorageByNamespace: true,
          mockApollo,
          storageLimitEnforced: true,
          isFreeNamespace: false,
        });
        await waitForPromises();
      });

      it('does not render the new storage design', () => {
        expect(findStorageUsageStatistics().exists()).toBe(false);
      });
    });
  });

  describe('with rootStorageStatistics available on namespace', () => {
    beforeEach(async () => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
      await waitForPromises();
    });

    it('renders total usage', async () => {
      expect(findTotalUsage().text()).toContain(
        numberToHumanSize(
          mockedNamespaceStorageResponse.data.namespace.rootStorageStatistics.storageSize,
        ),
      );
    });

    describe('with additional_repo_storage_by_namespace feature', () => {
      it('usage_graph component hidden is when feature is false', async () => {
        expect(findUsageGraph().exists()).toBe(true);
        expect(findUsageStatistics().exists()).toBe(false);
        expect(findStorageInlineAlert().exists()).toBe(false);
      });

      it('usage_statistics component is rendered when feature is true', async () => {
        mockApollo = createMockApolloProvider();

        createComponent({
          mockApollo,
          additionalRepoStorageByNamespace: true,
        });
        await waitForPromises();

        expect(findUsageStatistics().exists()).toBe(true);
        expect(findUsageGraph().exists()).toBe(false);
        expect(findStorageInlineAlert().exists()).toBe(true);
      });
    });

    describe('findStorageInlineAlert', () => {
      it('does not show storage inline alert if namespace is empty', async () => {
        // creating failed mock provider will make namespace = {}
        mockApollo = createFailedMockApolloProvider();
        createComponent({
          additionalRepoStorageByNamespace: true,
          storageLimitEnforced: true,
          isFreeNamespace: true,
          mockApollo,
        });

        await waitForPromises();
        expect(findStorageInlineAlert().exists()).toBe(false);
      });
    });
  });

  describe('without rootStorageStatistics available on namespace', () => {
    it('renders Not applicable for totalUsage when no rootStorageStatistics is provided', async () => {
      const namespaceWithoutStatistics = { ...mockedNamespaceStorageResponse };
      namespaceWithoutStatistics.data.namespace.rootStorageStatistics = null;
      mockApollo = createMockApolloProvider(namespaceWithoutStatistics);
      createComponent({ mockApollo });
      await waitForPromises();

      expect(findTotalUsage().text()).toContain('Not applicable');
    });
  });
});
