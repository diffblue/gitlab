import { GlAvatar, GlAvatarLink, GlBadge, GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourcesListItem from 'ee/ci/catalog/components/list/ci_resources_list_item.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
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
        RouterLink: true,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findResourceName = () => wrapper.findComponent(GlButton);
  const findResourceDescription = () => wrapper.findByText(defaultProps.resource.description);
  const findUserLink = () => wrapper.findByTestId('user-link');
  const findTimeAgoMessage = () => wrapper.findComponent(GlSprintf);
  const findFavorites = () => wrapper.findByTestId('stats-favorites');
  const findForks = () => wrapper.findByTestId('stats-forks');

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the resource avatar and passes the right props', () => {
      const { icon, id, name } = defaultProps.resource;
      expect(findAvatar().exists()).toBe(true);
      expect(findAvatar().props()).toMatchObject({
        entityId: getIdFromGraphQLId(id),
        entityName: name,
        src: icon,
      });
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
      expect(findUserLink().attributes('href')).toBe(resource.versions.nodes[0].author.webUrl);
    });

    describe('release time', () => {
      describe('when there is no release data', () => {
        beforeEach(() => {
          createComponent({ props: { resource: { ...resource, versions: null } } });
        });

        it('does not render the release', () => {
          expect(findTimeAgoMessage().exists()).toBe(false);
        });

        it('renders the generic `unreleased` badge', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe('Unreleased');
        });
      });

      describe('when there is release data', () => {
        beforeEach(() => {
          createComponent();
        });

        it('renders the time since the resource was released', () => {
          expect(findTimeAgoMessage().exists()).toBe(true);
        });

        it('renders the version badge', () => {
          expect(findBadge().exists()).toBe(true);
          expect(findBadge().text()).toBe('1.0.0');
        });
      });
    });
  });

  describe('statistics', () => {
    describe('when there are no statistics', () => {
      beforeEach(() => {
        createComponent({
          props: {
            resource: {
              forksCount: 0,
              starCount: 0,
            },
          },
        });
      });

      it('render favorites as 0', () => {
        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe('0');
      });

      it('render forks as 0', () => {
        expect(findForks().exists()).toBe(true);
        expect(findForks().text()).toBe('0');
      });
    });

    describe('where there are statistics', () => {
      beforeEach(() => {
        createComponent();
      });

      it('render favorites', () => {
        expect(findFavorites().exists()).toBe(true);
        expect(findFavorites().text()).toBe(String(defaultProps.resource.starCount));
      });

      it('render forks', () => {
        expect(findForks().exists()).toBe(true);
        expect(findForks().text()).toBe(String(defaultProps.resource.forksCount));
      });
    });
  });
});
