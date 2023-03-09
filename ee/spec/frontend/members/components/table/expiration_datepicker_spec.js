import { GlDatepicker } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { member } from 'jest/members/mock_data';
import ExpirationDatepicker from '~/members/components/table/expiration_datepicker.vue';
import { MEMBER_TYPES } from '~/members/constants';

describe('ExpirationDatepicker', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mount(ExpirationDatepicker, {
      provide: {
        namespace: MEMBER_TYPES.user,
      },
      propsData,
    });
  };

  const findDatepicker = () => wrapper.findComponent(GlDatepicker);

  it.each`
    canOverride | isOverridden | expected
    ${true}     | ${true}      | ${false}
    ${true}     | ${false}     | ${true}
    ${false}    | ${false}     | ${false}
  `(
    'sets `disabled` prop to $expected when `canOverride` is $canOverride and `member.isOverridden` is $isOverridden',
    ({ canOverride, isOverridden, expected }) => {
      createComponent({
        permissions: {
          canUpdate: true,
          canOverride,
        },
        member: { ...member, isOverridden },
      });

      expect(findDatepicker().props('disabled')).toBe(expected);
    },
  );
});
