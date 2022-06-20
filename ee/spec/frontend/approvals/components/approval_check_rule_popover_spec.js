import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from 'ee/approvals/components/approval_check_rule_popover.vue';
import { LICENSE_CHECK_NAME, APPROVAL_RULE_CONFIGS } from 'ee/approvals/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(component, {
      propsData: { rule: {}, ...props },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('computed props', () => {
    const securityApprovalsHelpPagePath = `${TEST_HOST}/documentation`;

    beforeEach(async () => {
      createComponent({ securityApprovalsHelpPagePath });
      await nextTick();
    });

    describe('showLicenseCheckPopover', () => {
      it('return true if the rule type is "License-Check"', async () => {
        wrapper.setProps({ rule: { name: LICENSE_CHECK_NAME } });
        await nextTick();
        expect(wrapper.vm.showLicenseCheckPopover).toBe(true);
      });
      it('return false if the rule type is "License-Check"', async () => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        await nextTick();
        expect(wrapper.vm.showLicenseCheckPopover).toBe(false);
      });
    });

    describe('approvalConfig', () => {
      it('returns "License-Check" config', async () => {
        wrapper.setProps({ rule: { name: LICENSE_CHECK_NAME } });
        await nextTick();
        expect(wrapper.vm.approvalRuleConfig.title).toBe(
          APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].title,
        );
        expect(wrapper.vm.approvalRuleConfig.popoverText).toBe(
          APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].popoverText,
        );
        expect(wrapper.vm.approvalRuleConfig.documentationText).toBe(
          APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].documentationText,
        );
      });
      it('returns an undefined config', async () => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        await nextTick();
        expect(wrapper.vm.approvalConfig).toBe(undefined);
      });
    });

    describe('documentationLink', () => {
      it('returns documentation link for "License-Check"', async () => {
        wrapper.setProps({ rule: { name: 'License-Check' } });
        await nextTick();
        expect(wrapper.vm.documentationLink).toBe(securityApprovalsHelpPagePath);
      });
      it('returns empty text', async () => {
        const text = '';
        wrapper.setProps({ rule: { name: 'FooRule' } });
        await nextTick();
        expect(wrapper.vm.documentationLink).toBe(text);
      });
    });

    describe('popoverTriggerId', () => {
      beforeEach(() => {
        createComponent({ rule: { name: 'rule-title' } });
      });

      it('returns popover id', () => {
        const expectedPopoverTriggerId = 'reportInfo-rule-title';

        expect(wrapper.vm.popoverTriggerId).toBe(expectedPopoverTriggerId);
      });
    });
  });
});
