import { shallowMount } from '@vue/test-utils';
import ViolationReason from 'ee/compliance_dashboard/components/violations_report/violations/reason.vue';
import UserAvatar from 'ee/compliance_dashboard/components/violations_report/shared/user_avatar.vue';
import { MERGE_REQUEST_VIOLATION_MESSAGES } from 'ee/compliance_dashboard/constants';
import { mapViolations } from 'ee/compliance_dashboard/graphql/mappers';
import { createComplianceViolation } from '../../../mock_data';

describe('ViolationReason component', () => {
  let wrapper;
  const { violatingUser: user } = mapViolations([createComplianceViolation()])[0];
  const reasons = Object.keys(MERGE_REQUEST_VIOLATION_MESSAGES);

  const findAvatar = () => wrapper.findComponent(UserAvatar);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(ViolationReason, { propsData });
  };

  describe('violation message', () => {
    it.each(reasons)('renders the violation message for the reason %s', (reason) => {
      createComponent({ reason });

      expect(wrapper.text()).toContain(MERGE_REQUEST_VIOLATION_MESSAGES[reason]);
    });
  });

  describe('violation user', () => {
    it('does not render a user avatar by default', () => {
      createComponent({ reason: reasons[0] });

      expect(findAvatar().exists()).toBe(false);
    });

    it('renders a user avatar when the user prop is set', () => {
      createComponent({ reason: reasons[0], user });

      expect(findAvatar().props('user')).toBe(user);
    });
  });
});
