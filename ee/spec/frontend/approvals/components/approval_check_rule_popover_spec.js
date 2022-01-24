import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import component from 'ee/approvals/components/approval_check_rule_popover.vue';
import {
  VULNERABILITY_CHECK_NAME,
  LICENSE_CHECK_NAME,
  APPROVAL_RULE_CONFIGS,
} from 'ee/approvals/constants';
import { TEST_HOST } from 'helpers/test_constants';

describe('Approval Check Popover', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(component, {
      propsData: { rule: {} },
    });
  });

  describe('computed props', () => {
    const securityApprovalsHelpPagePath = `${TEST_HOST}/documentation`;

    beforeEach(async () => {
      wrapper.setProps({ securityApprovalsHelpPagePath });
      await nextTick();
    });

    describe('showVulnerabilityCheckPopover', () => {
      it('return true if the rule type is "Vulnerability-Check"', async () => {
        wrapper.setProps({ rule: { name: VULNERABILITY_CHECK_NAME } });
        await nextTick();
        expect(wrapper.vm.showVulnerabilityCheckPopover).toBe(true);
      });
      it('return false if the rule type is "Vulnerability-Check"', async () => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        await nextTick();
        expect(wrapper.vm.showVulnerabilityCheckPopover).toBe(false);
      });
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
      it('returns "Vulnerability-Check" config', async () => {
        wrapper.setProps({ rule: { name: VULNERABILITY_CHECK_NAME } });
        await nextTick();
        expect(wrapper.vm.approvalRuleConfig.title).toBe(
          APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].title,
        );
        expect(wrapper.vm.approvalRuleConfig.popoverText).toBe(
          APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].popoverText,
        );
        expect(wrapper.vm.approvalRuleConfig.documentationText).toBe(
          APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].documentationText,
        );
      });
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
      it('returns documentation link for "Vulnerability-Check"', async () => {
        wrapper.setProps({ rule: { name: 'Vulnerability-Check' } });
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
  });
});
