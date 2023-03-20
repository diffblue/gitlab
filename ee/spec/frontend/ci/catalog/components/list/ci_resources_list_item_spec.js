import { GlAvatar, GlAvatarLink, GlBadge, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';
import { mockCatalogResourceItem } from '../../mock';

describe('CiResourcesListItem', () => {
  let wrapper;

  const resource = mockCatalogResourceItem;
  const defaultProps = {
    resource,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourcesListItem, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findResourceName = () => wrapper.findComponent(GlButton);
  const findResourceDescription = () => wrapper.findByText(defaultProps.resource.description);
  const findUserLink = () => wrapper.findComponent(GlLink);
  const findTimeAgoMessage = () => wrapper.findComponent(GlSprintf);
  const findFavorites = () => wrapper.findByTestId('stats-favorites');
  const findForks = () => wrapper.findByTestId('stats-forks');

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the resource avatar', () => {
      expect(findAvatar().exists()).toBe(true);
    });

    it('renders the resource avatar link', () => {
      expect(findAvatarLink().attributes('href')).toBe(resource.webPath);
    });

    it('renders the resource name button', () => {
      expect(findResourceName().exists()).toBe(true);
      expect(findResourceName().attributes('href')).toBe(resource.webPath);
    });

    it('renders the resource version badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the resource description', () => {
      expect(findResourceDescription().exists()).toBe(true);
    });

    it('renders the user link', () => {
      expect(findUserLink().exists()).toBe(true);
      expect(findUserLink().attributes('href')).toBe(resource.lastUpdate.user.webUrl);
    });

    it('renders the time since the resource was released', () => {
      expect(findTimeAgoMessage().exists()).toBe(true);
    });
  });
  describe('statistics', () => {
    describe('when there are no statistics', () => {
      beforeEach(() => {
        createComponent({
          props: {
            resource: {
              statistics: {},
              lastUpdate: {
                user: {
                  name: 'username',
                  webUrl: 'path/to/profile',
                },
              },
            },
          },
        });
      });

      it('does not render favorites', () => {
        expect(findFavorites().exists()).toBe(false);
      });

      it('does not render forks', () => {
        expect(findForks().exists()).toBe(false);
      });
    });

    describe('where there are statistics', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does render favorites', () => {
        expect(findFavorites().exists()).toBe(true);
      });

      it('does render forks', () => {
        expect(findForks().exists()).toBe(true);
      });
    });
  });
});
