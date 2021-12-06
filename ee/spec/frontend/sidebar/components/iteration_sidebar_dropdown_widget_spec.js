import { shallowMount } from '@vue/test-utils';
import IterationSidebarDropdownWidget from 'ee/sidebar/components/iteration_sidebar_dropdown_widget.vue';
import SidebarDropdownWidget from 'ee/sidebar/components/sidebar_dropdown_widget.vue';
import { IssuableType } from '~/issues/show/constants';

describe('IterationSidebarDropdownWidget', () => {
  let wrapper;

  const defaultProps = {
    attrWorkspacePath: 'attr/workspace/path',
    iid: 'iid',
    issuableType: IssuableType.Issue,
    workspacePath: 'workspace/path',
  };

  const createComponent = () =>
    shallowMount(IterationSidebarDropdownWidget, {
      propsData: defaultProps,
    });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('SidebarDropdownWidget component', () => {
    it('renders', () => {
      wrapper = createComponent();

      expect(wrapper.findComponent(SidebarDropdownWidget).props()).toEqual({
        ...defaultProps,
        issuableAttribute: 'iteration',
      });
    });
  });
});
