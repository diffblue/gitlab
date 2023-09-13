import { GlAlert, GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { cloneDeep } from 'lodash';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { captureException } from '~/ci/runner/sentry_utils';
import { NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE } from 'ee/usage_quotas/storage/constants';
import NamespaceStorageApp from 'ee/usage_quotas/storage/components/namespace_storage_app.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import getNamespaceStorageQuery from 'ee/usage_quotas/storage/queries/namespace_storage.query.graphql';
import getDependencyProxyTotalSizeQuery from 'ee/usage_quotas/storage/queries/dependency_proxy_usage.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import SearchAndSortBar from 'ee/usage_quotas/components/search_and_sort_bar/search_and_sort_bar.vue';
import StorageUsageStatistics from 'ee/usage_quotas/storage/components/storage_usage_statistics.vue';
import DependencyProxyUsage from 'ee/usage_quotas/storage/components/dependency_proxy_usage.vue';
import ContainerRegistryUsage from 'ee/usage_quotas/storage/components/container_registry_usage.vue';
import {
  defaultNamespaceProvideValues,
  mockedNamespaceStorageResponse,
  mockDependencyProxyResponse,
} from '../mock_data';

jest.mock('~/ci/runner/sentry_utils');

Vue.use(VueApollo);

describe('NamespaceStorageApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const getNamespaceStorageHandler = jest.fn();
  const getDependencyProxyTotalSizeHandler = jest.fn();

  const findDependencyProxy = () => wrapper.findComponent(DependencyProxyUsage);
  const findStorageUsageStatistics = () => wrapper.findComponent(StorageUsageStatistics);
  const findSearchAndSortBar = () => wrapper.findComponent(SearchAndSortBar);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findPrevButton = () => wrapper.findByTestId('prevButton');
  const findNextButton = () => wrapper.findByTestId('nextButton');
  const findBreakdownSubtitle = () => wrapper.findByTestId('breakdown-subtitle');
  const findContainerRegistry = () => wrapper.findComponent(ContainerRegistryUsage);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = mountExtended(NamespaceStorageApp, {
      apolloProvider: createMockApollo([
        [getNamespaceStorageQuery, getNamespaceStorageHandler],
        [getDependencyProxyTotalSizeQuery, getDependencyProxyTotalSizeHandler],
      ]),
      provide: {
        ...defaultNamespaceProvideValues,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    getNamespaceStorageHandler.mockResolvedValue(mockedNamespaceStorageResponse);
    getDependencyProxyTotalSizeHandler.mockResolvedValue(mockDependencyProxyResponse);
  });

  describe('Namespace usage overview', () => {
    beforeEach(async () => {
      createComponent({
        provide: {
          purchaseStorageUrl: 'some-fancy-url',
        },
      });
      await waitForPromises();
    });

    it('shows the namespace storage breakdown subtitle', () => {
      expect(findBreakdownSubtitle().text()).toBe(NAMESPACE_STORAGE_BREAKDOWN_SUBTITLE);
    });

    it('renders purchase more storage button', () => {
      const purchaseButton = wrapper.findComponent(GlButton);

      expect(purchaseButton.exists()).toBe(true);
      expect(purchaseButton.attributes('href')).toBe('some-fancy-url');
    });
  });

  describe('Dependency proxy usage', () => {
    it('shows the dependency proxy usage component', async () => {
      createComponent({
        provide: { userNamespace: false },
      });
      await waitForPromises();

      expect(findDependencyProxy().exists()).toBe(true);
    });

    it('does not display the dependency proxy for personal namespaces', () => {
      createComponent({
        provide: { userNamespace: true },
      });

      expect(findDependencyProxy().exists()).toBe(false);
    });
  });

  describe('Container registry usage', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('will be rendered', () => {
      expect(findContainerRegistry().exists()).toBe(true);
    });

    it('will have receive relevant props', () => {
      const {
        containerRegistrySize,
        containerRegistrySizeIsEstimated,
      } = mockedNamespaceStorageResponse.data.namespace.rootStorageStatistics;
      expect(findContainerRegistry().props()).toEqual({
        containerRegistrySize,
        containerRegistrySizeIsEstimated,
      });
    });
  });

  describe('project list', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the 2 projects', () => {
      expect(findProjectList().props('projects')).toHaveLength(2);
    });
  });

  describe('sorting projects', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          isUsingProjectEnforcement: false,
        },
      });
    });

    it('sets default sorting', () => {
      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE_SIZE_DESC',
        }),
      );
      const projectList = findProjectList();
      expect(projectList.props('sortBy')).toBe('storage');
      expect(projectList.props('sortDesc')).toBe(true);
    });

    it('forms a sorting order string for STORAGE sorting', async () => {
      findProjectList().vm.$emit('sortChanged', { sortBy: 'storage', sortDesc: false });
      await waitForPromises();
      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE_SIZE_ASC',
        }),
      );
    });

    it('ignores invalid sorting types', async () => {
      findProjectList().vm.$emit('sortChanged', { sortBy: 'yellow', sortDesc: false });
      await waitForPromises();
      expect(getNamespaceStorageHandler).toHaveBeenCalledTimes(1);
    });
  });

  describe('filtering projects', () => {
    const sampleSearchTerm = 'GitLab';

    beforeEach(() => {
      createComponent();
    });

    it('triggers search if user enters search input', async () => {
      expect(getNamespaceStorageHandler).toHaveBeenNthCalledWith(
        1,
        expect.objectContaining({ searchTerm: '' }),
      );
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();

      expect(getNamespaceStorageHandler).toHaveBeenNthCalledWith(
        2,
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );
    });

    it('triggers search if user clears the entered search input', async () => {
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();

      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );

      findSearchAndSortBar().vm.$emit('onFilter', '');
      await waitForPromises();

      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: '' }),
      );
    });

    it('triggers search with empty string if user enters short search input', async () => {
      findSearchAndSortBar().vm.$emit('onFilter', sampleSearchTerm);
      await waitForPromises();
      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: sampleSearchTerm }),
      );

      const sampleShortSearchTerm = 'Gi';
      findSearchAndSortBar().vm.$emit('onFilter', sampleShortSearchTerm);
      await waitForPromises();

      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({ searchTerm: '' }),
      );
    });
  });

  describe('projects table pagination component', () => {
    const namespaceWithPageInfo = cloneDeep(mockedNamespaceStorageResponse);
    namespaceWithPageInfo.data.namespace.projects.pageInfo.hasNextPage = true;

    beforeEach(() => {
      getNamespaceStorageHandler.mockResolvedValue(namespaceWithPageInfo);
    });

    it('has "Prev" button disabled', async () => {
      createComponent();
      await waitForPromises();

      expect(findPrevButton().attributes().disabled).toBe('disabled');
    });

    it('has "Next" button enabled', async () => {
      createComponent();
      await waitForPromises();

      expect(findNextButton().attributes().disabled).toBeUndefined();
    });

    describe('apollo calls', () => {
      beforeEach(async () => {
        namespaceWithPageInfo.data.namespace.projects.pageInfo.hasPreviousPage = true;
        getDependencyProxyTotalSizeHandler.mockResolvedValue(namespaceWithPageInfo);
        createComponent();

        await waitForPromises();
      });

      it('contains correct `first` and `last` values when clicking "Prev" button', () => {
        findPrevButton().trigger('click');
        expect(getNamespaceStorageHandler).toHaveBeenCalledTimes(2);
        expect(getNamespaceStorageHandler).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({ first: undefined, last: expect.any(Number) }),
        );
      });

      it('contains `first` value when clicking "Next" button', () => {
        findNextButton().trigger('click');
        expect(getNamespaceStorageHandler).toHaveBeenCalledTimes(2);
        expect(getNamespaceStorageHandler).toHaveBeenNthCalledWith(
          2,
          expect.objectContaining({ first: expect.any(Number) }),
        );
      });
    });

    describe('handling failed apollo requests', () => {
      beforeEach(async () => {
        getNamespaceStorageHandler.mockRejectedValue(new Error('Network error!'));
        createComponent();
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

  describe('storage-usage-statistics', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the new storage design', () => {
      expect(findStorageUsageStatistics().exists()).toBe(true);
    });

    it('passes costFactoredStorageSize as usedStorage', () => {
      expect(findStorageUsageStatistics().props('usedStorage')).toBe(
        mockedNamespaceStorageResponse.data.namespace.rootStorageStatistics.costFactoredStorageSize,
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
            getNamespaceStorageHandler.mockRejectedValue(new Error('Network error!'));
          } else if (queryLoading) {
            getNamespaceStorageHandler.mockImplementation(() => new Promise(() => {}));
          }

          createComponent();
          await waitForPromises();

          expect(findStorageUsageStatistics().props('loading')).toBe(expectedValue);
        },
      );
    });
  });

  // https://docs.gitlab.com/ee/user/usage_quotas#project-storage-limit
  describe('Namespace under Project type storage enforcement', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets default sorting', () => {
      expect(getNamespaceStorageHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          sortKey: 'STORAGE',
        }),
      );

      const projectList = findProjectList();
      expect(projectList.props('sortBy')).toBe(null);
      expect(projectList.props('sortDesc')).toBe(true);
    });
  });
});
