import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
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

    beforeEach((done) => {
      wrapper.setProps({ securityApprovalsHelpPagePath });
      Vue.nextTick(done);
    });

    describe('showVulnerabilityCheckPopover', () => {
      it('return true if the rule type is "Vulnerability-Check"', (done) => {
        wrapper.setProps({ rule: { name: VULNERABILITY_CHECK_NAME } });
        Vue.nextTick(() => {
          expect(wrapper.vm.showVulnerabilityCheckPopover).toBe(true);
          done();
        });
      });
      it('return false if the rule type is "Vulnerability-Check"', (done) => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.showVulnerabilityCheckPopover).toBe(false);
          done();
        });
      });
    });

    describe('showLicenseCheckPopover', () => {
      it('return true if the rule type is "License-Check"', (done) => {
        wrapper.setProps({ rule: { name: LICENSE_CHECK_NAME } });
        Vue.nextTick(() => {
          expect(wrapper.vm.showLicenseCheckPopover).toBe(true);
          done();
        });
      });
      it('return false if the rule type is "License-Check"', (done) => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.showLicenseCheckPopover).toBe(false);
          done();
        });
      });
    });

    describe('approvalConfig', () => {
      it('returns "Vulnerability-Check" config', (done) => {
        wrapper.setProps({ rule: { name: VULNERABILITY_CHECK_NAME } });
        Vue.nextTick(() => {
          expect(wrapper.vm.approvalRuleConfig.title).toBe(
            APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].title,
          );
          expect(wrapper.vm.approvalRuleConfig.popoverText).toBe(
            APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].popoverText,
          );
          expect(wrapper.vm.approvalRuleConfig.documentationText).toBe(
            APPROVAL_RULE_CONFIGS[VULNERABILITY_CHECK_NAME].documentationText,
          );
          done();
        });
      });
      it('returns "License-Check" config', (done) => {
        wrapper.setProps({ rule: { name: LICENSE_CHECK_NAME } });
        Vue.nextTick(() => {
          expect(wrapper.vm.approvalRuleConfig.title).toBe(
            APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].title,
          );
          expect(wrapper.vm.approvalRuleConfig.popoverText).toBe(
            APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].popoverText,
          );
          expect(wrapper.vm.approvalRuleConfig.documentationText).toBe(
            APPROVAL_RULE_CONFIGS[LICENSE_CHECK_NAME].documentationText,
          );
          done();
        });
      });
      it('returns an undefined config', (done) => {
        wrapper.setProps({ rule: { name: 'FooRule' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.approvalConfig).toBe(undefined);
          done();
        });
      });
    });

    describe('documentationLink', () => {
      it('returns documentation link for "License-Check"', (done) => {
        wrapper.setProps({ rule: { name: 'License-Check' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.documentationLink).toBe(securityApprovalsHelpPagePath);
          done();
        });
      });
      it('returns documentation link for "Vulnerability-Check"', (done) => {
        wrapper.setProps({ rule: { name: 'Vulnerability-Check' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.documentationLink).toBe(securityApprovalsHelpPagePath);
          done();
        });
      });
      it('returns empty text', (done) => {
        const text = '';
        wrapper.setProps({ rule: { name: 'FooRule' } });
        Vue.nextTick(() => {
          expect(wrapper.vm.documentationLink).toBe(text);
          done();
        });
      });
    });
  });
});
