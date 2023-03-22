import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CatalogHeader from 'ee/ci/catalog/components/list/catalog_header.vue';

describe('CatalogHeader', () => {
  let wrapper;

  const defaultProps = {};
  const defaultProvide = {
    pageTitle: 'Catalog page',
    pageDescription: 'This is a nice catalog page',
  };

  const findTitle = () => wrapper.findByText(defaultProvide.pageTitle);
  const findDescription = () => wrapper.findByText(defaultProvide.pageDescription);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CatalogHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: defaultProvide,
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the Catalog title and description', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findDescription().exists()).toBe(true);
    });
  });
});
