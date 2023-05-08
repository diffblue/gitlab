import StatusFilters from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filters.vue';
import StatusFilter from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/status_filter.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  NEWLY_DETECTED,
  PREVIOUSLY_EXISTING,
} from 'ee/security_orchestration/components/policy_editor/scan_result_policy/scan_filters/constants';

describe('StatusFilters', () => {
  let wrapper;

  const testStateNew = 'new_needs_triage';
  const testStatePreviouslyDetected = 'detected';
  const selectedNewlyDetected = { [NEWLY_DETECTED]: [testStateNew] };
  const selectedPreviouslyExisting = { [PREVIOUSLY_EXISTING]: [testStatePreviouslyDetected] };
  const selectedBothFilters = { ...selectedNewlyDetected, ...selectedPreviouslyExisting };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(StatusFilters, {
      propsData: {
        ...props,
      },
    });
  };

  const findStatusFilters = () => wrapper.findAllComponents(StatusFilter);

  it('renders nothing initially', () => {
    createComponent();

    expect(findStatusFilters()).toHaveLength(0);
  });

  describe('select', () => {
    it.each`
      selected                      | filtersCount
      ${selectedNewlyDetected}      | ${1}
      ${selectedPreviouslyExisting} | ${1}
      ${selectedBothFilters}        | ${2}
    `(
      'renders $filtersCount filter(s) based for selected $selected',
      ({ selected, filtersCount }) => {
        createComponent({ selected });

        expect(findStatusFilters()).toHaveLength(filtersCount);
      },
    );

    it('should emit input events on statuses changes', () => {
      createComponent({ selected: selectedBothFilters });

      findStatusFilters().at(0).vm.$emit('input', []);
      findStatusFilters().at(1).vm.$emit('input', []);

      expect(wrapper.emitted('input')).toEqual([
        [
          {
            [NEWLY_DETECTED]: [],
            [PREVIOUSLY_EXISTING]: [testStatePreviouslyDetected],
          },
        ],
        [
          {
            [NEWLY_DETECTED]: [testStateNew],
            [PREVIOUSLY_EXISTING]: [],
          },
        ],
      ]);
    });

    it('should select PREVIOUSLY_EXISTING vulnerability state and emit input event', async () => {
      createComponent({ selected: selectedNewlyDetected });

      await findStatusFilters().at(0).vm.$emit('change-group', PREVIOUSLY_EXISTING);

      expect(wrapper.emitted('input')).toEqual([
        [{ [NEWLY_DETECTED]: null, [PREVIOUSLY_EXISTING]: [] }],
      ]);
    });

    it.each`
      selected                      | disabled
      ${selectedNewlyDetected}      | ${undefined}
      ${selectedPreviouslyExisting} | ${undefined}
      ${selectedBothFilters}        | ${'true'}
    `('renders filter with disabled=$disabled for states $selected', ({ selected, disabled }) => {
      createComponent({ selected });

      for (let i = 0; i < findStatusFilters().length; i += 1) {
        expect(findStatusFilters().at(i).attributes('disabled')).toEqual(disabled);
      }
    });
  });

  describe('remove', () => {
    it('should remove filter', async () => {
      createComponent({ selected: selectedNewlyDetected });

      await findStatusFilters().at(0).vm.$emit('remove');

      expect(wrapper.emitted('remove')).toHaveLength(1);
    });
  });
});
