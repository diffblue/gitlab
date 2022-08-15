import { mount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import StatusBadge, { VARIANTS } from 'ee/vue_shared/security_reports/components/status_badge.vue';
import { VULNERABILITY_STATES } from 'ee/vulnerabilities/constants';

describe('StatusBadge', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);

  const createWrapper = (state) => {
    wrapper = mount(StatusBadge, {
      propsData: {
        state,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each(Object.entries(VARIANTS))(
    'the vulnerability state badge has the correct style for the %s state',
    (state, variant) => {
      createWrapper(state);
      const badge = findBadge();

      expect(badge.props('variant')).toBe(variant);
      expect(badge.text()).toBe(VULNERABILITY_STATES[state]);
    },
  );

  it('throws if the passed state is not supported', () => {
    expect(() => {
      createWrapper('invalid-prop');
    }).toThrow('Invalid prop: custom validator check failed for prop');
  });
});
