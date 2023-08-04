import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ExportRequirementsModal from 'ee/requirements/components/export_requirements_modal.vue';

const FIELDS = ExportRequirementsModal.fields;
const TEST_INDEX = 0;
const createComponent = ({ requirementCount = 42, email = 'admin@example.com' } = {}) =>
  shallowMount(ExportRequirementsModal, {
    propsData: {
      requirementCount,
      email,
    },
  });

describe('ExportRequirementsModal', () => {
  let wrapper;

  const findSelectAllCheckbox = () =>
    wrapper.find('.scrollbox-header').findComponent(GlFormCheckbox);
  const findFieldCheckboxes = () =>
    wrapper.find('.scrollbox-body').findAllComponents(GlFormCheckbox);
  const findFieldCheckbox = (index) => findFieldCheckboxes().at(index);
  const toggleSelectAllCheckbox = () => findSelectAllCheckbox().vm.$emit('change');
  const toggleFieldCheckbox = (index) => findFieldCheckbox(index).vm.$emit('change');
  const expectAllFieldCheckboxesSelected = (selected = true) => {
    findFieldCheckboxes().wrappers.forEach((fieldCheckbox) => {
      if (selected) {
        expect(fieldCheckbox.attributes('checked')).toBe('true');
      } else {
        expect(fieldCheckbox.attributes('checked')).toBeUndefined();
      }
    });
  };
  const emitModalPrimaryEvent = () => wrapper.findComponent(GlModal).vm.$emit('primary');

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('field checkbox', () => {
    const field = FIELDS[TEST_INDEX];

    it('is checked by default and the corresponding field key included in the emit', () => {
      expect(findFieldCheckbox(TEST_INDEX).attributes('checked')).toBe('true');

      emitModalPrimaryEvent();
      expect(wrapper.emitted('export')[0][0].includes(field.key)).toBe(true);
    });

    it('is unchecks on click and the corresponding field key is included in the emit', async () => {
      await toggleFieldCheckbox(TEST_INDEX);
      expect(findFieldCheckbox(TEST_INDEX).attributes('checked')).toBeUndefined();

      emitModalPrimaryEvent();
      expect(wrapper.emitted('export')[0][0].includes(field.key)).not.toBe(true);
    });

    it('can be checked again and the corresponding field key is included back in the emit when the field has been unchecked', async () => {
      await toggleFieldCheckbox(TEST_INDEX);
      expect(findFieldCheckbox(TEST_INDEX).attributes('checked')).toBeUndefined();

      await toggleFieldCheckbox(TEST_INDEX);
      expect(findFieldCheckbox(TEST_INDEX).attributes('checked')).toBe('true');

      emitModalPrimaryEvent();
      expect(wrapper.emitted('export')[0][0].includes(field.key)).toBe(true);
    });
  });

  describe('"Select all" toggle', () => {
    it('selects all if few are selected', async () => {
      await toggleFieldCheckbox(TEST_INDEX);

      findFieldCheckboxes().wrappers.forEach((fieldCheckbox, index) => {
        if (index === TEST_INDEX) {
          expect(fieldCheckbox.attributes('checked')).toBeUndefined();
        } else {
          expect(fieldCheckbox.attributes('checked')).toBe('true');
        }
      });

      await toggleSelectAllCheckbox();
      expectAllFieldCheckboxesSelected();
    });

    it('unchecks all if all are selected', async () => {
      expectAllFieldCheckboxesSelected();

      await toggleSelectAllCheckbox();
      expectAllFieldCheckboxesSelected(false);
    });

    it('selects all if none are selected', async () => {
      await toggleSelectAllCheckbox();
      expectAllFieldCheckboxesSelected(false);

      await toggleSelectAllCheckbox();
      expectAllFieldCheckboxesSelected();
    });
  });

  describe('template', () => {
    it('GlModal open click emits export event', () => {
      emitModalPrimaryEvent();

      expect(wrapper.emitted('export')).toHaveLength(1);
    });

    it('renders checkboxes for advanced exporting', () => {
      expect(findFieldCheckboxes()).toHaveLength(FIELDS.length);
    });

    it('renders Select all checkbox', () => {
      expect(findSelectAllCheckbox().exists()).toBe(true);
    });
  });
});
