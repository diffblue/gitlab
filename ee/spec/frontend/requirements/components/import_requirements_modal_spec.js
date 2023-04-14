import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ImportRequirementsModal from 'ee/requirements/components/import_requirements_modal.vue';

const TEST_PROJECT_PATH = 'gitLabTest';
const TEST_FILE = new File(['foo'], 'foo.csv');

const createComponent = ({ projectPath = TEST_PROJECT_PATH } = {}) =>
  shallowMount(ImportRequirementsModal, {
    propsData: {
      projectPath,
    },
  });

describe('ImportRequirementsModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const selectFile = (file = TEST_FILE) => {
    const input = wrapper.find('input[type="file"]');
    Object.defineProperty(input.element, 'files', { value: [file] });
    return input.trigger('change');
  };

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('"Import requirements" button', () => {
    it('disables modal button when file is absent', () => {
      expect(findModal().attributes('ok-disabled')).toBe('true');
    });

    it('returns false when file is present', async () => {
      await selectFile();
      expect(findModal().attributes('ok-disabled')).toBeUndefined();
    });
  });

  describe('methods', () => {
    describe('handleCSVFile', () => {
      it('sets the first file selected', async () => {
        await selectFile();
        findModal().vm.$emit('ok');

        expect(wrapper.emitted('import')[0][0].file).toBe(TEST_FILE);
      });
    });
  });

  describe('template', () => {
    it('GlModal open click emits file and projectPath', async () => {
      await selectFile();
      findModal().vm.$emit('ok');

      const emitted = wrapper.emitted('import')[0][0];

      expect(emitted.file).toBe(TEST_FILE);
      expect(emitted.projectPath).toBe(TEST_PROJECT_PATH);
    });
  });
});
