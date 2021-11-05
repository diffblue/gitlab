import { mount } from '@vue/test-utils';
import StorageApp from 'ee/storage_counter/components/app.vue';
import Project from 'ee/storage_counter/components/project.vue';
import ProjectsTable from 'ee/storage_counter/components/projects_table.vue';
import StorageInlineAlert from 'ee/storage_counter/components/storage_inline_alert.vue';
import TemporaryStorageIncreaseModal from 'ee/storage_counter/components/temporary_storage_increase_modal.vue';
import UsageStatistics from 'ee/storage_counter/components/usage_statistics.vue';
import { formatUsageSize } from 'ee/storage_counter/utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import UsageGraph from '~/vue_shared/components/storage_counter/usage_graph.vue';
import { namespaceData, withRootStorageStatistics } from '../mock_data';

const TEST_LIMIT = 1000;

describe('Storage counter app', () => {
  let wrapper;

  const findTotalUsage = () => wrapper.find("[data-testid='total-usage']");
  const findPurchaseStorageLink = () => wrapper.find("[data-testid='purchase-storage-link']");
  const findTemporaryStorageIncreaseButton = () =>
    wrapper.find("[data-testid='temporary-storage-increase-button']");
  const findUsageGraph = () => wrapper.find(UsageGraph);
  const findUsageStatistics = () => wrapper.find(UsageStatistics);
  const findStorageInlineAlert = () => wrapper.find(StorageInlineAlert);
  const findProjectsTable = () => wrapper.find(ProjectsTable);
  const findPrevButton = () => wrapper.find('[data-testid="prevButton"]');
  const findNextButton = () => wrapper.find('[data-testid="nextButton"]');

  const createComponent = ({
    props = {},
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

    wrapper = mount(StorageApp, {
      propsData: { namespacePath: 'h5bp', helpPagePath: 'help', ...props },
      mocks: { $apollo },
      directives: {
        GlModalDirective: createMockDirective(),
      },
      provide: {
        glFeatures: {
          additionalRepoStorageByNamespace,
        },
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
    wrapper.setData({
      namespace: namespaceData,
    });

    await wrapper.vm.$nextTick();

    expect(wrapper.findAll(Project)).toHaveLength(3);
  });

  describe('limit', () => {
    it('when limit is set it renders limit information', async () => {
      wrapper.setData({
        namespace: namespaceData,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.text()).toContain(formatUsageSize(namespaceData.limit));
    });

    it('when limit is 0 it does not render limit information', async () => {
      wrapper.setData({
        namespace: { ...namespaceData, limit: 0 },
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.text()).not.toContain(formatUsageSize(0));
    });
  });

  describe('with rootStorageStatistics information', () => {
    it('renders total usage', async () => {
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      await wrapper.vm.$nextTick();

      expect(findTotalUsage().text()).toContain(withRootStorageStatistics.totalUsage);
    });
  });

  describe('with additional_repo_storage_by_namespace feature', () => {
    it('usage_graph component hidden is when feature is false', async () => {
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      await wrapper.vm.$nextTick();

      expect(findUsageGraph().exists()).toBe(true);
      expect(findUsageStatistics().exists()).toBe(false);
      expect(findStorageInlineAlert().exists()).toBe(false);
    });

    it('usage_statistics component is rendered when feature is true', async () => {
      createComponent({
        additionalRepoStorageByNamespace: true,
        namespace: withRootStorageStatistics,
      });

      await wrapper.vm.$nextTick();

      expect(findUsageStatistics().exists()).toBe(true);
      expect(findUsageGraph().exists()).toBe(false);
      expect(findStorageInlineAlert().exists()).toBe(true);
    });
  });

  describe('without rootStorageStatistics information', () => {
    it('renders N/A', async () => {
      wrapper.setData({
        namespace: namespaceData,
      });

      await wrapper.vm.$nextTick();

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
        createComponent({ props: { purchaseStorageUrl: 'customers.gitlab.com' } });
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
      props                                             | isVisible
      ${{}}                                             | ${false}
      ${{ isTemporaryStorageIncreaseVisible: 'false' }} | ${false}
      ${{ isTemporaryStorageIncreaseVisible: 'true' }}  | ${true}
    `('with $props', ({ props, isVisible }) => {
      beforeEach(() => {
        createComponent({ props });
      });

      it(`renders button = ${isVisible}`, () => {
        expect(findTemporaryStorageIncreaseButton().exists()).toBe(isVisible);
      });
    });

    describe('when temporary storage increase is visible', () => {
      beforeEach(() => {
        createComponent({ props: { isTemporaryStorageIncreaseVisible: 'true' } });
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
        expect(value).toEqual(StorageApp.modalId);
      });

      it('renders modal', () => {
        expect(wrapper.find(TemporaryStorageIncreaseModal).props()).toEqual({
          limit: formatUsageSize(TEST_LIMIT),
          modalId: StorageApp.modalId,
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

      findProjectsTable().vm.$emit('search', sampleSearchTerm);

      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);
    });

    it('triggers search if user clears the entered search input', () => {
      const projectsTable = findProjectsTable();

      expect(wrapper.vm.searchTerm).toBe('');

      projectsTable.vm.$emit('search', sampleSearchTerm);

      expect(wrapper.vm.searchTerm).toBe(sampleSearchTerm);

      projectsTable.vm.$emit('search', '');

      expect(wrapper.vm.searchTerm).toBe('');
    });

    it('does not trigger search if user enters short search input', () => {
      expect(wrapper.vm.searchTerm).toBe('');

      findProjectsTable().vm.$emit('search', sampleShortSearchTerm);

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
