import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import Approval from 'ee/compliance_dashboard/components/merge_requests/statuses/approval.vue';

describe('ApprovalStatus component', () => {
  let wrapper;

  const findIcon = () => wrapper.find('.ci-icon');
  const findLink = () => wrapper.find(GlLink);

  const createComponent = (status) => {
    return shallowMount(Approval, {
      propsData: { status },
      stubs: {
        CiIcon: {
          props: { status: Object },
          template: `<div class="ci-icon">{{ status.icon }}</div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with an approval status', () => {
    const approvalStatus = 'success';

    beforeEach(() => {
      wrapper = createComponent(approvalStatus);
    });

    it('links to the approval status', () => {
      expect(findLink().attributes('href')).toEqual(
        'https://docs.gitlab.com/ee/user/compliance/compliance_report/#approval-status-and-separation-of-duties',
      );
    });

    it('renders an icon with the approval status', () => {
      expect(findIcon().text()).toEqual(`status_${approvalStatus}`);
    });

    describe.each`
      status       | icon                | group                      | tooltip
      ${'success'} | ${'status_success'} | ${'success'}               | ${'Adheres to separation of duties'}
      ${'warning'} | ${'status_warning'} | ${'success-with-warnings'} | ${'At least one rule does not adhere to separation of duties'}
      ${'failed'}  | ${'status_failed'}  | ${'failed'}                | ${'Fails to adhere to separation of duties'}
    `('returns the correct values for $status', ({ status, icon, group, tooltip }) => {
      beforeEach(() => {
        wrapper = createComponent(status);
      });

      it('returns the correct icon', () => {
        expect(wrapper.vm.icon).toEqual(icon);
      });

      it('returns the correct group', () => {
        expect(wrapper.vm.group).toEqual(group);
      });

      it('returns the correct tooltip', () => {
        expect(wrapper.vm.tooltip).toEqual(tooltip);
      });
    });
  });
});
