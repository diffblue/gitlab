import { shallowMount } from '@vue/test-utils';
import CiResourcesList from 'ee/ci/catalog/components/list/ci_resources_list.vue';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';

describe('CiResourcesList', () => {
  let wrapper;

  const defaultProps = {
    resources: [{ id: 1 }, { id: 2 }],
  };

  const findResourcesListItems = () => wrapper.findAllComponents(CiResourcesListItem);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CiResourcesList, {
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

    it('renders a list of ResourcesListItem components', () => {
      expect(findResourcesListItems()).toHaveLength(defaultProps.resources.length);
    });
  });
});
