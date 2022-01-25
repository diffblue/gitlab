import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { nextTick } from 'vue';
import ImportRequirementsModal from 'ee/requirements/components/import_requirements_modal.vue';

const createComponent = ({ projectPath = 'gitLabTest' } = {}) =>
  shallowMount(ImportRequirementsModal, {
    propsData: {
      projectPath,
    },
  });

describe('ImportRequirementsModal', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('importDisabled', () => {
      it('returns true when file is absent', () => {
        expect(wrapper.vm.importDisabled).toBe(true);
      });

      it('returns false when file is present', () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({ file: 'Some file' });

        expect(wrapper.vm.importDisabled).toBe(false);
      });
    });
  });

  describe('methods', () => {
    describe('handleCSVFile', () => {
      it('sets the first file selected', async () => {
        const file = 'some file';

        const event = {
          target: {
            files: [file],
          },
        };
        wrapper.vm.handleCSVFile(event);

        await nextTick();
        expect(wrapper.vm.file).toBe(file);
      });
    });
  });

  describe('template', () => {
    it('GlModal open click emits file and projectPath', () => {
      const file = 'some file';

      // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
      // eslint-disable-next-line no-restricted-syntax
      wrapper.setData({
        file,
      });

      wrapper.findComponent(GlModal).vm.$emit('ok');

      const emitted = wrapper.emitted('import')[0][0];

      expect(emitted.file).toBe(file);
      expect(emitted.projectPath).toBe(wrapper.vm.projectPath);
    });
  });
});
