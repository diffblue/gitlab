import { GlModal, GlFormCheckbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import ExportRequirementsModal from 'ee/requirements/components/export_requirements_modal.vue';

const createComponent = ({ requirementCount = 42, email = 'admin@example.com' } = {}) =>
  shallowMount(ExportRequirementsModal, {
    propsData: {
      requirementCount,
      email,
    },
  });

describe('ExportRequirementsModal', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('handleExport', () => {
      it('emits `export` event', () => {
        wrapper.vm.handleExport();

        const emitted = wrapper.emitted('export');

        expect(emitted).toBeDefined();
      });
    });

    describe('toggleField', () => {
      it("removes field if it's already selected", async () => {
        const [field] = wrapper.vm.$options.fields;

        wrapper.vm.toggleField(field.key);

        expect(wrapper.vm.selectedFields.includes(field)).toBe(false);
      });

      it("adds field if it's not selected", async () => {
        const [field] = wrapper.vm.$options.fields;

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        await wrapper.setData({
          selectedFields: wrapper.vm.$options.fields.slice(1).map((f) => f.key),
        });

        wrapper.vm.toggleField(field.key);

        expect(wrapper.vm.selectedFields.includes(field.key)).toBe(true);
      });
    });

    describe('isFieldSelected', () => {
      it('returns true when field is in selectedFields', () => {
        const [field] = wrapper.vm.$options.fields;

        expect(wrapper.vm.isFieldSelected(field.key)).toBe(true);
      });

      it('returns false when field is in selectedFields', async () => {
        const [field] = wrapper.vm.$options.fields;

        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        await wrapper.setData({
          selectedFields: wrapper.vm.$options.fields.slice(1).map((f) => f.key),
        });

        expect(wrapper.vm.isFieldSelected(field.key)).toBe(false);
      });
    });

    describe('toggleAllFields', () => {
      it('selects all if few are selected', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        await wrapper.setData({
          selectedFields: wrapper.vm.$options.fields.slice(1).map((f) => f.key),
        });

        wrapper.vm.toggleAllFields();

        expect(wrapper.vm.selectedFields).toHaveLength(wrapper.vm.$options.fields.length);
      });

      it('unchecks all if all are selected', () => {
        wrapper.vm.toggleAllFields();

        expect(wrapper.vm.selectedFields).toHaveLength(0);
      });

      it('selects all if none are selected', async () => {
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        await wrapper.setData({
          selectedFields: [],
        });

        wrapper.vm.toggleAllFields();

        expect(wrapper.vm.selectedFields).toHaveLength(wrapper.vm.$options.fields.length);
      });
    });
  });

  describe('template', () => {
    it('GlModal open click emits export event', () => {
      wrapper.findComponent(GlModal).vm.$emit('ok');

      const emitted = wrapper.emitted('export');

      expect(emitted).toBeDefined();
    });

    it('renders checkboxes for advanced exporting', () => {
      const checkboxes = wrapper.find('.scrollbox-body').findAllComponents(GlFormCheckbox);

      expect(checkboxes).toHaveLength(wrapper.vm.$options.fields.length);
    });

    it('renders Select all checkbox', () => {
      const checkbox = wrapper.find('.scrollbox-header').findAllComponents(GlFormCheckbox);

      expect(checkbox).toHaveLength(1);
    });
  });
});
