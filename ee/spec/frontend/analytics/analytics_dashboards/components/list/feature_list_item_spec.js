import { GlAvatar, GlIcon, GlBadge, GlButton } from '@gitlab/ui';
import FeatureListItem from 'ee/analytics/analytics_dashboards/components/list/feature_list_item.vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { __ } from '~/locale';

describe('FeatureListItem', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findButton = () => wrapper.findComponent(GlButton);
  const findButtonLink = () => findButton().find('a');

  const defaultProps = {
    title: 'Hello world',
    description: 'Some description',
    to: 'some-path',
  };

  const createWrapper = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(FeatureListItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('default behavior', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the feature title', () => {
      expect(wrapper.text()).toContain(defaultProps.title);
    });

    it('renders the dashboard description', () => {
      expect(wrapper.text()).toContain(defaultProps.description);
    });

    it('renders the setup icon', () => {
      expect(findIcon().props()).toMatchObject({
        name: 'cloud-gear',
        size: 16,
      });
    });

    it('renders the setup avatar', () => {
      expect(findAvatar().props()).toMatchObject({
        entityName: '💡',
        entityId: 1,
        size: 32,
      });
    });

    it('renders the button with default text', () => {
      expect(findButton().text()).toBe(__('Set up'));
    });
  });

  describe('button path', () => {
    beforeEach(() => {
      createWrapper({ to: 'foo-bar' }, mountExtended);
    });

    it('renders the button link', () => {
      expect(findButtonLink().attributes('to')).toBe('foo-bar');
    });
  });

  describe('badge text', () => {
    beforeEach(() => {
      createWrapper({ badgeText: 'waiting' });
    });

    it('renders a badge with the badge text', () => {
      expect(findBadge().text()).toBe('waiting');
    });
  });

  describe('action text', () => {
    beforeEach(() => {
      createWrapper({ actionText: 'do something' });
    });

    it('renders a badge with the badge text', () => {
      expect(findButton().text()).toBe('do something');
    });
  });

  describe('avatar name', () => {
    beforeEach(() => {
      createWrapper({ avatarName: 'foobar' });
    });

    it('sets the avatar name', () => {
      expect(findAvatar().props('entityName')).toBe('foobar');
    });
  });
});
