import { shallowMount } from '@vue/test-utils';
import CollapsibleProjectStorageDetail from 'ee/usage_quotas/storage/components/collapsible_project_storage_detail.vue';
import ProjectList from 'ee/usage_quotas/storage/components/project_list.vue';
import { projects } from '../mock_data';

let wrapper;

const createComponent = ({ additionalRepoStorageByNamespace = false } = {}) => {
  wrapper = shallowMount(ProjectList, {
    propsData: {
      projects,
      additionalPurchasedStorageSize: 0,
    },
    provide: {
      glFeatures: {
        additionalRepoStorageByNamespace,
      },
    },
  });
};

const findTableRows = () => wrapper.findAllComponents(CollapsibleProjectStorageDetail);

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

  describe('with additional repo storage feature flag ', () => {
    beforeEach(() => {
      createComponent({ additionalRepoStorageByNamespace: true });
    });

    it('renders regular project rows by default', () => {
      expect(findTableRows()).toHaveLength(3);
    });
  });
});
