import { shallowMount } from '@vue/test-utils';
import ViolationReason from 'ee/compliance_dashboard/components/violations/reason.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import UserAvatar from 'ee/compliance_dashboard/components/shared/user_avatar.vue';
import {
  MERGE_REQUEST_VIOLATION_MESSAGES,
  MERGE_REQUEST_VIOLATION_REASONS,
} from 'ee/compliance_dashboard/constants';
import { createUser } from '../../mock_data';

describe('ViolationReason component', () => {
  let wrapper;
  const user = convertObjectPropsToCamelCase(createUser(1));

  const getViolationMessage = (reason) =>
    MERGE_REQUEST_VIOLATION_MESSAGES[MERGE_REQUEST_VIOLATION_REASONS[reason]];
  const findAvatar = () => wrapper.findComponent(UserAvatar);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(ViolationReason, { propsData });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('violation message', () => {
    it.each`
      reason | message
      ${0}   | ${getViolationMessage(0)}
      ${1}   | ${getViolationMessage(1)}
      ${2}   | ${getViolationMessage(2)}
    `(
      'renders the violation message "$message" for the reason code $reason',
      ({ reason, message }) => {
        createComponent({ reason });

        expect(wrapper.text()).toContain(message);
      },
    );
  });

  describe('violation user', () => {
    it('does not render a user avatar by default', () => {
      createComponent({ reason: 0 });

      expect(findAvatar().exists()).toBe(false);
    });

    it('renders a user avatar when the user prop is set', () => {
      createComponent({ reason: 0, user });

      expect(findAvatar().props('user')).toBe(user);
    });
  });
});
