import { shallowMount } from '@vue/test-utils';
import ciResourceDetailsPage from 'ee/ci/catalog/components/pages/ci_resource_details_page.vue';

describe('ciResourceDetailsPage', () => {
  let wrapper;

  const defaultProps = {};

  const findTitle = () => wrapper.find('h1');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ciResourceDetailsPage, {
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

    it('renders the Catalog details title', () => {
      expect(findTitle().text()).toBe('Catalog item details page');
    });
  });
});
