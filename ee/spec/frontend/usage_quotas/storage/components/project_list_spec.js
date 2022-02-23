import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CollapsibleProjectStorageDetail from 'ee/usage_quotas/storage/components/collapsible_project_storage_detail.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import {
  PROJECT_TABLE_LABEL_STORAGE_USAGE,
  PROJECT_TABLE_LABEL_USAGE,
} from 'ee/usage_quotas/storage/constants';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ props = {}, additionalRepoStorageByNamespace = false } = {}) => {
  wrapper = shallowMountExtended(ProjectList, {
    propsData: {
      projects,
      additionalPurchasedStorageSize: 0,
      ...props,
    },
    provide: {
      glFeatures: {
        additionalRepoStorageByNamespace,
      },
    },
  });
};

const findTableRows = () => wrapper.findAllComponents(CollapsibleProjectStorageDetail);
const findUsageLabel = () => wrapper.findByTestId('usage-label');

describe('ProjectList', () => {
  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders regular project rows by default', () => {
    expect(findTableRows()).toHaveLength(3);
  });

  describe('usage column', () => {
    it('renders passed `usageLabel` as column label', () => {
      createComponent({ props: { usageLabel: PROJECT_TABLE_LABEL_STORAGE_USAGE } });

      expect(findUsageLabel().text()).toBe(PROJECT_TABLE_LABEL_STORAGE_USAGE);
    });

    it('renders `Usage` as column label by default', () => {
      createComponent();

      expect(findUsageLabel().text()).toBe(PROJECT_TABLE_LABEL_USAGE);
    });
  });

  describe('with additional repo storage feature flag ', () => {
    beforeEach(() => {
      createComponent({ additionalRepoStorageByNamespace: true });
    });

    it('renders regular project rows by default', () => {
      expect(findTableRows()).toHaveLength(3);
    });
  });
});
