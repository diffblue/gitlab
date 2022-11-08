import { GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerMaintenanceNoteField from 'ee_component/ci/runner/components/runner_maintenance_note_field.vue';

const mockValue = 'Note.';

describe('RunnerMaintenanceNoteField', () => {
  let wrapper;

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findTextarea = () => wrapper.find('textarea');

  const createComponent = (options) => {
    wrapper = mountExtended(RunnerMaintenanceNoteField, {
      propsData: {
        value: mockValue,
      },
      ...options,
    });
  };

  describe('when runner_maintenance_note is enabled', () => {
    let mockInput;

    const provide = {
      glFeatures: { runnerMaintenanceNote: true },
    };

    beforeEach(() => {
      mockInput = jest.fn();

      createComponent({
        listeners: {
          input: mockInput,
        },
        provide,
      });
    });

    it('has value', () => {
      expect(findTextarea().element.value).toBe(mockValue);
    });

    it('emits input', () => {
      const newValue = 'Note 2.';

      findTextarea().setValue(newValue);
      findTextarea().trigger('input');

      expect(mockInput).toHaveBeenCalledWith(newValue);
    });
  });

  describe('when runner_maintenance_note is disabled', () => {
    beforeEach(() => {
      createComponent({
        provide: {
          glFeatures: { runnerMaintenanceNote: false },
        },
      });
    });

    it('does not render field', () => {
      expect(findFormGroup().exists()).toBe(false);
      expect(findFormInputGroup().exists()).toBe(false);
    });
  });
});
