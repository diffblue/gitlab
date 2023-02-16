import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerFormFields from '~/ci/runner/components/runner_form_fields.vue';

const mockMaintenanceNote = 'A note.';

describe('RunnerFormFields', () => {
  let wrapper;

  const findTextarea = (name) => wrapper.find(`textarea[name="${name}"]`);

  const createComponent = ({ runner } = {}) => {
    wrapper = mountExtended(RunnerFormFields, {
      propsData: {
        value: runner,
      },
      provide: {
        glFeatures: {
          runnerMaintenanceNote: true,
        },
      },
    });
  };

  it('updates runner maintenance note', async () => {
    createComponent();
    await nextTick();

    expect(wrapper.emitted('input')).toBe(undefined);

    findTextarea('maintenance-note').setValue(mockMaintenanceNote);
    await nextTick();

    expect(wrapper.emitted('input')[0][0]).toEqual({
      maintenanceNote: mockMaintenanceNote,
    });
  });
});
