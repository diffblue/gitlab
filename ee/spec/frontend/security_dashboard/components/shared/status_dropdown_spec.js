import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StatusDropdown from 'ee/security_dashboard/components/shared/status_dropdown.vue';
import { VULNERABILITY_STATE_OBJECTS } from 'ee/vulnerabilities/constants';

describe('Status Dropdown component', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);

  const createWrapper = () => {
    wrapper = shallowMount(StatusDropdown, {
      stubs: {
        GlDropdown,
        GlDropdownItem,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the correct placeholder', () => {
    expect(findDropdown().props('text')).toBe('Set status');
  });

  describe.each(Object.keys(VULNERABILITY_STATE_OBJECTS).map((k, i) => [k, i]))(
    'state - %s',
    (state, index) => {
      const status = VULNERABILITY_STATE_OBJECTS[state];

      it(`renders ${state}`, () => {
        expect(findDropdownItems().at(index).text()).toBe(
          `${status.dropdownText} ${status.dropdownDescription}`,
        );
      });

      it(`emits an event when clicked - ${state}`, () => {
        findDropdownItems().at(index).vm.$emit('click');
        expect(wrapper.emitted().change[0][0]).toEqual({
          action: status.action,
          payload: status.payload,
        });
      });
    },
  );
});
