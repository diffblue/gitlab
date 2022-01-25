import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import NamespaceStorageApp from 'ee/usage_quotas/storage/components/namespace_storage_app.vue';
import CollapsibleProjectStorageDetail from 'ee/usage_quotas/storage/components/collapsible_project_storage_detail.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import StorageInlineAlert from 'ee/usage_quotas/storage/components/storage_inline_alert.vue';
import TemporaryStorageIncreaseModal from 'ee/usage_quotas/storage/components/temporary_storage_increase_modal.vue';
import UsageStatistics from 'ee/usage_quotas/storage/components/usage_statistics.vue';
import UsageGraph from 'ee/usage_quotas/storage/components/usage_graph.vue';
import { formatUsageSize } from 'ee/usage_quotas/storage/utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import {
  namespaceData,
  withRootStorageStatistics,
  defaultNamespaceProvideValues,
} from '../mock_data';

const TEST_LIMIT = 1000;

describe('NamespaceStorageApp', () => {
  let wrapper;

  const findTotalUsage = () => wrapper.find("[data-testid='total-usage']");
  const findPurchaseStorageLink = () => wrapper.find("[data-testid='purchase-storage-link']");
  const findTemporaryStorageIncreaseButton = () =>
    wrapper.find("[data-testid='temporary-storage-increase-button']");
  const findUsageGraph = () => wrapper.findComponent(UsageGraph);
  const findUsageStatistics = () => wrapper.findComponent(UsageStatistics);
  const findStorageInlineAlert = () => wrapper.findComponent(StorageInlineAlert);
  const findProjectList = () => wrapper.findComponent(ProjectList);
  const findPrevButton = () => wrapper.find('[data-testid="prevButton"]');
  const findNextButton = () => wrapper.find('[data-testid="nextButton"]');

  const createComponent = ({
    provide = {},
    loading = false,
    additionalRepoStorageByNamespace = false,
    namespace = {},
  } = {}) => {
    const $apollo = {
      queries: {
        namespace: {
          loading,
        },
      },
    };

    wrapper = mount(NamespaceStorageApp, {
      mocks: { $apollo },
      directives: {
        GlModalDirective: createMockDirective(),
      },
      provide: {
        glFeatures: {
          additionalRepoStorageByNamespace,
        },
        ...defaultNamespaceProvideValues,
        ...provide,
      },
      data() {
        return {
          namespace,
        };
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the 2 projects', async () => {
    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    wrapper.setData({
      namespace: namespaceData,
    });

    await nextTick();

    expect(wrapper.findAllComponents(CollapsibleProjectStorageDetail)).toHaveLength(3);
  });

  describe('limit', () => {
    it('when limit is set it renders limit information', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        namespace: namespaceData,
      });

      await nextTick();

      expect(wrapper.text()).toContain(formatUsageSize(namespaceData.limit));
    });

    it('when limit is 0 it does not render limit information', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        namespace: { ...namespaceData, limit: 0 },
      });

      await nextTick();

      expect(wrapper.text()).not.toContain(formatUsageSize(0));
    });
  });

  describe('with rootStorageStatistics information', () => {
    it('renders total usage', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      await nextTick();

      expect(findTotalUsage().text()).toContain(withRootStorageStatistics.totalUsage);
    });
  });

  describe('with additional_repo_storage_by_namespace feature', () => {
    it('usage_graph component hidden is when feature is false', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      await nextTick();

      expect(findUsageGraph().exists()).toBe(true);
      expect(findUsageStatistics().exists()).toBe(false);
      expect(findStorageInlineAlert().exists()).toBe(false);
    });

    it('usage_statistics component is rendered when feature is true', async () => {
      createComponent({
        additionalRepoStorageByNamespace: true,
        namespace: withRootStorageStatistics,
      });

      await nextTick();

      expect(findUsageStatistics().exists()).toBe(true);
      expect(findUsageGraph().exists()).toBe(false);
      expect(findStorageInlineAlert().exists()).toBe(true);
    });
  });

  describe('without rootStorageStatistics information', () => {
    it('renders N/A', async () => {
      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        namespace: namespaceData,
      });

      await nextTick();

      expect(findTotalUsage().text()).toContain('N/A');
    });
  });

  describe('purchase storage link', () => {
    describe('when purchaseStorageUrl is not set', () => {
      it('does not render an additional link', () => {
        expect(findPurchaseStorageLink().exists()).toBe(false);
      });
    });

    describe('when purchaseStorageUrl is set', () => {
      beforeEach(() => {
        createComponent({ provide: { purchaseStorageUrl: 'customers.gitlab.com' } });
      });

      it('does render link', () => {
        const link = findPurchaseStorageLink();

        expect(link.exists()).toBe(true);
        expect(link.attributes('href')).toBe('customers.gitlab.com');
      });
    });
  });

  describe('temporary storage increase', () => {
    describe.each`
      provide                                           | isVisible
      ${{}}                                             | ${false}
      ${{ isTemporaryStorageIncreaseVisible: 'false' }} | ${false}
      ${{ isTemporaryStorageIncreaseVisible: 'true' }}  | ${true}
    `('with $provide', ({ provide, isVisible }) => {
      beforeEach(() => {
        createComponent({ provide });
      });

      it(`renders button = ${isVisible}`, () => {
        expect(findTemporaryStorageIncreaseButton().exists()).toBe(isVisible);
      });
    });

    describe('when temporary storage increase is visible', () => {
      beforeEach(() => {
        createComponent({ provide: { isTemporaryStorageIncreaseVisible: 'true' } });
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          namespace: {
            ...namespaceData,
            limit: TEST_LIMIT,
          },
        });
      });

      it('binds button to modal', () => {
        const { value } = getBinding(
          findTemporaryStorageIncreaseButton().element,
          'gl-modal-directive',
        );

        // Check for truthiness so we're assured we're not comparing two undefineds
        expect(value).toBeTruthy();
        expect(value).toEqual(NamespaceStorageApp.modalId);
      });

      it('renders modal', () => {
        expect(wrapper.findComponent(TemporaryStorageIncreaseModal).props()).toEqual({
          limit: formatUsageSize(TEST_LIMIT),
          modalId: NamespaceStorageApp.modalId,
        });
      });
    });
  });

  describe('filtering projects', () => {
    beforeEach(() => {
      createComponent({
        additionalRepoStorageByNamespace: true,
        namespace: withRootStorageStatistics,
      });
    });

    const sampleSearchTerm = 'GitLab';
    const sampleShortSearchTerm = '12';

    it('triggers search if user enters search input', () => {
      expect(wrapper.vm.searchTerm).toBe('');

      findProjectList().vm.$emit('search', sampleSearchTerm);

      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);
    });

    it('triggers search if user clears the entered search input', () => {
      const projectList = findProjectList();

      expect(wrapper.vm.searchTerm).toBe('');

      projectList.vm.$emit('search', sampleSearchTerm);

      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);

      projectList.vm.$emit('search', '');

      expect(wrapper.vm.searchTerm).toBe('');
    });

    it('does not trigger search if user enters short search input', () => {
      expect(wrapper.vm.searchTerm).toBe('');

      findProjectList().vm.$emit('search', sampleShortSearchTerm);

      expect(wrapper.vm.searchTerm).toBe('');
    });
  });

  describe('renders projects table pagination component', () => {
    const namespaceWithPageInfo = {
      namespace: {
        ...withRootStorageStatistics,
        projects: {
          ...withRootStorageStatistics.projects,
          pageInfo: {
            hasPreviousPage: false,
            hasNextPage: true,
          },
        },
      },
    };
    beforeEach(() => {
      createComponent(namespaceWithPageInfo);
    });

    it('with disabled "Prev" button', () => {
      expect(findPrevButton().attributes().disabled).toBe('disabled');
    });

    it('with enabled "Next" button', () => {
      expect(findNextButton().attributes().disabled).toBeUndefined();
    });
  });
});
