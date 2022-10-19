import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import HealthStatusDropdown from 'ee/sidebar/components/health_status/health_status_dropdown.vue';
import {
  HEALTH_STATUS_AT_RISK,
  HEALTH_STATUS_I18N_NO_STATUS,
  HEALTH_STATUS_NEEDS_ATTENTION,
  HEALTH_STATUS_ON_TRACK,
  healthStatusTextMap,
} from 'ee/sidebar/constants';

describe('HealthStatusDropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItemAt = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);

  const mountComponent = ({ healthStatus = HEALTH_STATUS_ON_TRACK } = {}) => {
    wrapper = shallowMount(HealthStatusDropdown, { propsData: { healthStatus } });
  };

  describe('dropdown text', () => {
    it.each`
      healthStatus                     | dropdownText
      ${HEALTH_STATUS_ON_TRACK}        | ${healthStatusTextMap[HEALTH_STATUS_ON_TRACK]}
      ${HEALTH_STATUS_NEEDS_ATTENTION} | ${healthStatusTextMap[HEALTH_STATUS_NEEDS_ATTENTION]}
      ${HEALTH_STATUS_AT_RISK}         | ${healthStatusTextMap[HEALTH_STATUS_AT_RISK]}
      ${null}                          | ${HEALTH_STATUS_I18N_NO_STATUS}
    `(
      'renders "$dropdownText" when health status = "$healthStatus"',
      ({ healthStatus, dropdownText }) => {
        mountComponent({ healthStatus });

        expect(findDropdown().props('text')).toBe(dropdownText);
      },
    );
  });

  describe('when dropdown item is clicked', () => {
    it.each`
      index | emitted
      ${0}  | ${null}
      ${1}  | ${HEALTH_STATUS_ON_TRACK}
      ${2}  | ${HEALTH_STATUS_NEEDS_ATTENTION}
      ${3}  | ${HEALTH_STATUS_AT_RISK}
    `('emits "change" event with value "$emitted" for item index $index', ({ index, emitted }) => {
      mountComponent();

      findDropdownItemAt(index).vm.$emit('click');

      expect(wrapper.emitted('change')).toEqual([[emitted]]);
    });
  });
});
