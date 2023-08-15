import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiResourceHeader from 'ee/ci/catalog/components/details/ci_resource_header.vue';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';

describe('CiResourceHeader', () => {
  let wrapper;

  const defaultProps = {
    description: 'This is the description of the repo',
    name: 'Ruby',
    resourceId: '1',
    rootNamespace: { id: 1, fullPath: '/group/project', name: 'my-dumb-project' },
    webPath: 'path/to/project',
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findVersionBadge = () => wrapper.findComponent(GlBadge);
  const findPipelineStatusBadge = () => wrapper.findComponent(CiBadgeLink);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(CiResourceHeader, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the project name and description', () => {
      expect(wrapper.html()).toContain(defaultProps.name);
      expect(wrapper.html()).toContain(defaultProps.description);
    });

    it('renders the namespace and project path', () => {
      expect(wrapper.html()).toContain(defaultProps.rootNamespace.fullPath);
      expect(wrapper.html()).toContain(defaultProps.rootNamespace.name);
    });

    it('does not render release information', () => {
      expect(findVersionBadge().exists()).toBe(false);
      expect(findPipelineStatusBadge().exists()).toBe(false);
    });

    it('renders the avatar', () => {
      const { resourceId, name } = defaultProps;

      expect(findAvatar().exists()).toBe(true);
      expect(findAvatarLink().exists()).toBe(true);
      expect(findAvatar().props()).toMatchObject({
        entityId: getIdFromGraphQLId(resourceId),
        entityName: name,
      });
    });
  });

  describe('when the project has a release', () => {
    const pipelineStatus = {
      detailsPath: 'path/to/pipeline',
      icon: 'status_success',
      text: 'passed',
      group: 'success',
    };

    describe.each`
      hasPipelineBadge | describeText | testText             | status
      ${true}          | ${'is'}      | ${'renders'}         | ${pipelineStatus}
      ${false}         | ${'is not'}  | ${'does not render'} | ${{}}
    `('and there $describeText a pipeline', ({ hasPipelineBadge, testText, status }) => {
      beforeEach(() => {
        createComponent({
          props: {
            pipelineStatus: status,
            latestVersion: { tagName: '1.0.0', tagPath: 'path/to/release' },
          },
        });
      });

      it('renders the version badge', () => {
        expect(findVersionBadge().exists()).toBe(true);
      });

      it(`${testText} the pipeline status badge`, () => {
        expect(findPipelineStatusBadge().exists()).toBe(hasPipelineBadge);
      });
    });
  });
});
