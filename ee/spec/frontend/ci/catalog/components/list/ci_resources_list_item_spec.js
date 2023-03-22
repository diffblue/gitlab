import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';

describe('CiResourcesList', () => {
  let wrapper;

  const defaultProps = {
    component: { id: 1 },
  };

  const findComponentId = () => wrapper.findByText(String(defaultProps.component.id));

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourcesListItem, {
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

    it('renders a component ID', () => {
      expect(findComponentId().exists()).toBe(true);
    });
  });
});
