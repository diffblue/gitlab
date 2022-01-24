import { mount } from '@vue/test-utils';
import {
  RuleDirectionOutbound,
  EndpointMatchModeAny,
  EndpointMatchModeLabel,
  RuleTypeEntity,
  RuleTypeCIDR,
  RuleTypeFQDN,
  PortMatchModePortProtocol,
  buildRule,
} from 'ee/threat_monitoring/components/policy_editor/network_policy/lib';
import PolicyRuleBuilder from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_builder.vue';
import PolicyRuleCIDR from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_cidr.vue';
import PolicyRuleEndpoint from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_endpoint.vue';
import PolicyRuleEntity from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_entity.vue';
import PolicyRuleFQDN from 'ee/threat_monitoring/components/policy_editor/network_policy/policy_rule_fqdn.vue';

describe('PolicyRuleBuilder component', () => {
  let wrapper;
  let rule;

  const factory = ({ propsData } = {}) => {
    wrapper = mount(PolicyRuleBuilder, {
      propsData: {
        rule,
        endpointMatchMode: EndpointMatchModeAny,
        endpointLabels: '',
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    rule = buildRule();
    factory();
  });

  function selectFirstOption(sel) {
    const el = wrapper.find(sel);
    el.findAll('option').at(1).setSelected();
    el.trigger('change');
  }

  const findEndpointLabels = () => wrapper.find("[data-testid='endpoint-labels']");
  const findRuleEndpoint = () => wrapper.findComponent(PolicyRuleEndpoint);
  const findRuleEntity = () => wrapper.findComponent(PolicyRuleEntity);
  const findRuleCIDR = () => wrapper.findComponent(PolicyRuleCIDR);
  const findRuleFQDN = () => wrapper.findComponent(PolicyRuleFQDN);
  const findPorts = () => wrapper.find("[data-testid='ports']");

  afterEach(() => {
    wrapper.destroy();
  });

  it('updates rule direction upon selecting', async () => {
    selectFirstOption("[id='direction']");
    await wrapper.vm.$nextTick();
    expect(rule.direction).toEqual(RuleDirectionOutbound);
  });

  it('emits endpoint-match-mode-change upon selecting', async () => {
    selectFirstOption("[data-testid='endpoint-match-mode']");
    await wrapper.vm.$nextTick();
    const event = wrapper.emitted()['endpoint-match-mode-change'];
    expect(event.length).toEqual(2);
    expect(event[0]).toEqual([EndpointMatchModeLabel]);
  });

  it('does not render endpoint labels input', () => {
    expect(findEndpointLabels().exists()).toBe(false);
  });

  describe('when endpoint match mode is labels', () => {
    beforeEach(() => {
      factory({
        propsData: {
          endpointMatchMode: EndpointMatchModeLabel,
        },
      });
    });

    it('renders endpoint labels input', () => {
      expect(findEndpointLabels().exists()).toBe(true);
    });

    it('emits endpoint-labels-change on change', async () => {
      const input = findEndpointLabels();
      input.setValue('foo:bar');
      await wrapper.vm.$nextTick();
      const event = wrapper.emitted()['endpoint-labels-change'];
      expect(event.length).toEqual(1);
      expect(event[0]).toEqual(['foo:bar']);
    });
  });

  it('emits rule-type-change upon selecting', async () => {
    selectFirstOption("[id='ruleMode']");
    await wrapper.vm.$nextTick();
    const event = wrapper.emitted()['rule-type-change'];
    expect(event.length).toEqual(2);
    expect(event[0]).toEqual([RuleTypeEntity]);
  });

  it('emits remove upon remove-button click', () => {
    wrapper.find("[data-testid='remove-rule']").trigger('click');
    expect(wrapper.emitted().remove.length).toEqual(1);
  });

  it('renders only endpoint rule component', () => {
    expect(findRuleEndpoint().exists()).toBe(true);
    expect(findRuleEntity().exists()).toBe(false);
    expect(findRuleCIDR().exists()).toBe(false);
    expect(findRuleFQDN().exists()).toBe(false);
  });

  describe('when policy type is entity', () => {
    beforeEach(() => {
      rule = buildRule(RuleTypeEntity);
      factory();
    });

    it('renders only entity rule component', () => {
      expect(findRuleEndpoint().exists()).toBe(false);
      expect(findRuleEntity().exists()).toBe(true);
      expect(findRuleCIDR().exists()).toBe(false);
      expect(findRuleFQDN().exists()).toBe(false);
    });

    it('updates entity types', async () => {
      const el = findRuleEntity();
      el.findAll('button')
        .filter((e) => e.text() === 'host')
        .trigger('click');
      await wrapper.vm.$nextTick();
      expect(rule.entities).toEqual(['host']);
    });
  });

  describe('when policy type is cidr', () => {
    beforeEach(() => {
      rule = buildRule(RuleTypeCIDR);
      factory();
    });

    it('renders only cidr rule component', () => {
      expect(findRuleEndpoint().exists()).toBe(false);
      expect(findRuleEntity().exists()).toBe(false);
      expect(findRuleCIDR().exists()).toBe(true);
      expect(findRuleFQDN().exists()).toBe(false);
    });

    it('updates cidr', async () => {
      const el = findRuleCIDR();
      el.setValue('0.0.0.0/24');
      el.trigger('change');
      await wrapper.vm.$nextTick();
      expect(rule.cidr).toEqual('0.0.0.0/24');
    });
  });

  describe('when policy type is fqdn', () => {
    beforeEach(() => {
      rule = buildRule(RuleTypeFQDN);
      factory();
    });

    it('renders only fqdn rule component', () => {
      expect(findRuleEndpoint().exists()).toBe(false);
      expect(findRuleEntity().exists()).toBe(false);
      expect(findRuleCIDR().exists()).toBe(false);
      expect(findRuleFQDN().exists()).toBe(true);
    });

    it('updates fqdn', async () => {
      const el = findRuleFQDN();
      el.setValue('some-service.com');
      el.trigger('change');
      await wrapper.vm.$nextTick();
      expect(rule.fqdn).toEqual('some-service.com');
    });
  });

  it('updates port match mode upon selecting', async () => {
    selectFirstOption("[id='portMatch']");
    await wrapper.vm.$nextTick();
    expect(rule.portMatchMode).toEqual(PortMatchModePortProtocol);
  });

  it('does not render ports input', () => {
    expect(findPorts().exists()).toBe(false);
  });

  describe('when port match mode is port/protocol', () => {
    beforeEach(() => {
      rule.portMatchMode = PortMatchModePortProtocol;
      factory();
    });

    it('renders ports input', () => {
      expect(findPorts().exists()).toBe(true);
    });

    it('updates ports', async () => {
      const input = findPorts();
      input.setValue('80/tcp');
      await wrapper.vm.$nextTick();
      expect(rule.ports).toEqual('80/tcp');
    });
  });
});
