import { GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PolicyPreviewHuman from 'ee/threat_monitoring/components/policy_editor/policy_preview_human.vue';
import PolicyPreview from 'ee/threat_monitoring/components/policy_editor/policy_preview.vue';

describe('PolicyPreview component', () => {
  let wrapper;

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findPolicyPreviewHuman = () => wrapper.findComponent(PolicyPreviewHuman);

  const factory = ({ propsData } = {}) => {
    wrapper = shallowMount(PolicyPreview, {
      propsData: {
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with policy description', () => {
    const policyDescription = '<strong>bar</strong><br><div>test</div><script></script>';

    beforeEach(() => {
      factory({
        propsData: {
          policyYaml: 'foo',
          policyDescription,
        },
      });
    });

    it('renders policy preview tabs', () => {
      expect(findTabs().element).toMatchSnapshot();
    });

    it('renders the policy preview human', () => {
      expect(findPolicyPreviewHuman().props('policyDescription')).toBe(policyDescription);
    });

    it('renders the first tab', () => {
      expect(findTabs().attributes().value).toEqual('0');
    });

    describe('initial tab', () => {
      it('selects initial tab', () => {
        factory({
          propsData: {
            policyYaml: 'foo',
            policyDescription: 'bar',
            initialTab: 1,
          },
        });
        expect(findTabs().attributes().value).toEqual('1');
      });
    });
  });

  describe('without policy description', () => {
    beforeEach(() => {
      factory({
        propsData: {
          policyYaml: 'foo',
        },
      });
    });
  });
});
