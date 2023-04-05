import { shallowMount } from '@vue/test-utils';
import ciResourcesPage from 'ee/ci/catalog/components/pages/ci_resources_page.vue';
import CatalogHeader from 'ee/ci/catalog/components/list/catalog_header.vue';
import CiResourcesList from 'ee/ci/catalog/components/list/ci_resources_list.vue';
import EmptyState from 'ee/ci/catalog/components/list/empty_state.vue';
import { mockCatalogResourceList } from 'ee/ci/catalog/constants';

describe('ciResourcesPage', () => {
  let wrapper;

  const defaultProps = {};

  const findCatalogHeader = () => wrapper.findComponent(CatalogHeader);
  const findCiResourcesList = () => wrapper.findComponent(CiResourcesList);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ciResourcesPage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Catalog Header', () => {
      expect(findCatalogHeader().exists()).toBe(true);
    });

    it('renders the resources list', () => {
      expect(findCiResourcesList().exists()).toBe(true);
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('passes down props to the resources list', () => {
      expect(findCiResourcesList().props()).toEqual({ resources: mockCatalogResourceList });
    });
  });
});
