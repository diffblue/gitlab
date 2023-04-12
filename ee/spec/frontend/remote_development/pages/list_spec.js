import { shallowMount } from '@vue/test-utils';
import WorkspacesList from 'ee/remote_development/pages/list.vue';
import EmptyState from 'ee/remote_development/components/list/empty_state.vue';

describe('remote_development/pages/list.vue', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const createComponent = () => {
    wrapper = shallowMount(WorkspacesList, {});
  };

  describe('when no workspaces exist', () => {
    it('should render empty workspace state', () => {
      createComponent();
      expect(findEmptyState().exists()).toBe(true);
    });
  });
});
