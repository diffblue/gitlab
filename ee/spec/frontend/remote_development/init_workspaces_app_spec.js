import { createWrapper } from '@vue/test-utils';
import { initWorkspacesApp } from 'ee/remote_development/init_workspaces_app';
import WorkspaceList from 'ee/remote_development/pages/list.vue';

describe('ee/remote_development/init_workspaces_app', () => {
  let wrapper;

  beforeEach(() => {
    document.body.innerHTML = '<div id="js-workspaces"></div>';
  });

  afterEach(() => {
    document.body.innerHTML = '';
    // Wrapper is not created from mount or shallowMount which is why it isn't auto destroyed
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  describe('initWorkspacesApp - integration', () => {
    beforeEach(() => {
      wrapper = createWrapper(initWorkspacesApp());
    });

    it('renders list state', () => {
      expect(wrapper.findComponent(WorkspaceList).exists()).toBe(true);
    });
  });

  describe('initWorkspacesApp - when mounting element not found', () => {
    it('returns null', () => {
      document.body.innerHTML = '<div>Look ma! Code!</div>';

      expect(initWorkspacesApp()).toBeNull();
    });
  });
});
