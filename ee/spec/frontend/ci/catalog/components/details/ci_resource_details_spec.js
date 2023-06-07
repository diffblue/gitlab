import { shallowMount } from '@vue/test-utils';
import CiResourceDetails from 'ee/ci/catalog/components/details/ci_resource_details.vue';

describe('CiResourceDetails', () => {
  let wrapper;

  const defaultProps = { readmeHtml: '<h1>Hello world</h1>' };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiResourceDetails, {
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

    it('renders the received HTML', () => {
      expect(wrapper.html()).toContain(defaultProps.readmeHtml);
    });
  });
});
