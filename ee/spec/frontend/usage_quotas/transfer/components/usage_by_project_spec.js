import { GlSkeletonLoader, GlAvatarLink, GlAvatarLabeled, GlKeysetPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsageByProject from 'ee/usage_quotas/transfer/components/usage_by_project.vue';
import { USAGE_BY_PROJECT_HEADER } from 'ee/usage_quotas/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { getGroupDataTransferEgressResponse } from '../mock_data';

describe('UsageByProject', () => {
  let wrapper;

  const {
    data: {
      group: { projects },
    },
  } = getGroupDataTransferEgressResponse;

  const defaultPropsData = {
    projects,
    loading: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(UsageByProject, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  it('renders `Usage by project` heading', () => {
    createComponent();

    expect(wrapper.findByRole('heading', { name: USAGE_BY_PROJECT_HEADER }).exists()).toBe(true);
  });

  describe('when `loading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          loading: true,
        },
      });
    });

    it('renders 10 rows of `GlSkeletonLoader` component', () => {
      expect(wrapper.findAllComponents(GlSkeletonLoader).length).toBe(20);
    });
  });

  describe('when `loading` prop is `false`', () => {
    it('renders `Project` column', () => {
      createComponent();

      const avatarLinksHref = wrapper
        .findAllComponents(GlAvatarLink)
        .wrappers.map((avatarLinkWrapper) => avatarLinkWrapper.attributes('href'));
      const expectedAvatarLinksHref = projects.nodes.map((node) => node.webUrl);

      const avatarLabeledProps = wrapper
        .findAllComponents(GlAvatarLabeled)
        .wrappers.map((avatarLabeledWrapper) => ({
          label: avatarLabeledWrapper.props('label'),
          entityName: avatarLabeledWrapper.attributes('entity-name'),
          entityId: avatarLabeledWrapper.attributes('entity-id'),
          src: avatarLabeledWrapper.attributes('src'),
        }));
      const expectedAvatarLabeledProps = projects.nodes.map((node) => ({
        label: node.nameWithNamespace,
        entityName: node.name,
        entityId: getIdFromGraphQLId(node.id).toString(),
        src: node.avatarUrl || undefined,
      }));

      expect(avatarLinksHref).toEqual(expectedAvatarLinksHref);
      expect(avatarLabeledProps).toEqual(expectedAvatarLabeledProps);
    });

    it('renders `Transfer data used` column', () => {
      createComponent();

      const dataUsedText = wrapper
        .findAllByTestId('transfer-data-used')
        .wrappers.map((dataUsedCell) => dataUsedCell.text());
      const expectedDataUsedText = [
        '14.07 MiB',
        '14.57 MiB',
        '15.56 MiB',
        '13.42 MiB',
        '15.05 MiB',
      ];

      expect(dataUsedText).toEqual(expectedDataUsedText);
    });

    describe('when there are no previous or additional pages', () => {
      it('does not render pagination', () => {
        createComponent();

        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('when there are additional pages of projects', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            projects: {
              ...projects,
              pageInfo: {
                ...projects.pageInfo,
                hasNextPage: true,
              },
            },
          },
        });
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when next button is clicked', () => {
        it('emits `next` event', () => {
          findPagination().vm.$emit('next', projects.pageInfo.endCursor);

          expect(wrapper.emitted('next')).toEqual([[projects.pageInfo.endCursor]]);
        });
      });
    });

    describe('when there are previous pages', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            projects: {
              ...projects,
              pageInfo: {
                ...projects.pageInfo,
                hasPreviousPage: true,
              },
            },
          },
        });
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });

      describe('when previous button is clicked', () => {
        it('emits `prev` event', () => {
          findPagination().vm.$emit('prev', projects.pageInfo.startCursor);

          expect(wrapper.emitted('prev')).toEqual([[projects.pageInfo.startCursor]]);
        });
      });
    });
  });
});
