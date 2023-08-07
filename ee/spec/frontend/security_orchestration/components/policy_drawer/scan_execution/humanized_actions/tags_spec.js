import { GlBadge } from '@gitlab/ui';
import PolicyDrawerTags from 'ee/security_orchestration/components/policy_drawer/scan_execution/humanized_actions/tags.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('PolicyDrawerTags', () => {
  let wrapper;

  const createComponent = (tags) => {
    wrapper = shallowMountExtended(PolicyDrawerTags, {
      propsData: {
        criteria: { tags },
      },
    });
  };

  const findBadges = () => wrapper.findAllComponents(GlBadge);

  it('renders nothing when action has no tags', () => {
    createComponent([]);

    expect(findBadges()).toHaveLength(0);
  });

  it('renders badges for each tag', () => {
    createComponent(['tag1', 'tag2']);

    expect(findBadges()).toHaveLength(2);
  });
});
