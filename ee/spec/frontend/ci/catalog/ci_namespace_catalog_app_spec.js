import { shallowMount } from '@vue/test-utils';
import CiNamespaceCatalogApp from 'ee/ci/catalog/ci_namespace_catalog_app.vue';
import CiCatalogHome from 'ee/ci/catalog/components/ci_catalog_home.vue';

describe('CiNamespaceCatalogApp', () => {
  let wrapper;

  const findCatalogHome = () => wrapper.findComponent(CiCatalogHome);

  const defaultProps = {};

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(CiNamespaceCatalogApp, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('Home component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the home component', () => {
      expect(findCatalogHome().exists()).toBe(true);
    });
  });
});
