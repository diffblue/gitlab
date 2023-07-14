import { nextTick } from 'vue';
import WorkspacesDropdownGroup from 'ee_component/remote_development/components/workspaces_dropdown_group/workspaces_dropdown_group.vue';
import CEWebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import WebIdeLink from 'ee_component/vue_shared/components/web_ide_link.vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

jest.mock('~/lib/utils/url_utility');

describe('ee_component/vue_shared/components/web_ide_link', () => {
  const projectId = 1;
  const newWorkspacePath = 'workspaces/new';
  const projectPath = 'bar/foo';
  let wrapper;

  function createComponent({ props = {}, provide = {} } = {}) {
    wrapper = shallowMountExtended(WebIdeLink, {
      propsData: {
        projectId,
        projectPath,
        ...props,
      },
      provide: {
        ...provide,
      },
      stubs: {
        WorkspacesDropdownGroup: stubComponent(WorkspacesDropdownGroup),
        WebIdeLink: CEWebIdeLink,
      },
    });
  }

  const findCEWebIdeLink = () => wrapper.findComponent(CEWebIdeLink);
  const findWorkspacesDropdownGroup = () => wrapper.findComponent(WorkspacesDropdownGroup);

  it('passes down properties to the CEWebIdeLink component', () => {
    createComponent({ props: { isBlob: true } });

    expect(findCEWebIdeLink().props('isBlob')).toBe(true);
  });

  it('bubbles up edit event emitted by CEWebIdeLink', () => {
    createComponent();

    findCEWebIdeLink().vm.$emit('edit', true);

    expect(wrapper.emitted('edit')).toEqual([[true]]);
  });

  describe('when CE Web IDE Link component emits "shown" event', () => {
    describe('when workspaces dropdown group is visible', () => {
      beforeEach(async () => {
        createComponent({
          props: { projectId, projectPath },
          provide: {
            newWorkspacePath,
          },
        });

        findCEWebIdeLink().vm.$emit('shown');

        await nextTick();
      });

      it('provides required parameters to workspaces dropdown group', () => {
        expect(findWorkspacesDropdownGroup().props()).toEqual({
          projectId,
          projectFullPath: projectPath,
          newWorkspacePath,
        });
      });

      it('hides workspaces dropdown group when actions button emits hidden event', async () => {
        expect(findWorkspacesDropdownGroup().exists()).toBe(true);

        findCEWebIdeLink().vm.$emit('hidden');

        await nextTick();

        expect(findWorkspacesDropdownGroup().exists()).toBe(false);
      });
    });
  });
});
