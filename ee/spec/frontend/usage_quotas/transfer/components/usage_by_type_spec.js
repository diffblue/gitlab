import { GlSkeletonLoader, GlTableLite, GlIcon, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsageByType from 'ee/usage_quotas/transfer/components/usage_by_type.vue';
import SectionedPercentageBar from '~/usage_quotas/components/sectioned_percentage_bar.vue';
import { s__, __ } from '~/locale';
import {
  EGRESS_TYPE_ARTIFACTS,
  EGRESS_TYPE_REPOSITORY,
  EGRESS_TYPE_PACKAGES,
  EGRESS_TYPE_REGISTRY,
} from 'ee/usage_quotas/transfer/constants';
import { getProjectDataTransferEgressResponse } from '../mock_data';

describe('UsageByType', () => {
  let wrapper;

  const {
    nodes: egressNodes,
  } = getProjectDataTransferEgressResponse.data.project.dataTransfer.egressNodes;

  const defaultPropsData = {
    egressNodes,
    loading: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(UsageByType, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findSectionedPercentageBar = () => wrapper.findComponent(SectionedPercentageBar);

  describe('when `loading` prop is `true`', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          loading: true,
        },
      });
    });

    it('renders `GlSkeletonLoader` component', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('renders 4 rows of `GlSkeletonLoader` component', () => {
      expect(findTable().findAllComponents(GlSkeletonLoader)).toHaveLength(8);
    });
  });

  describe('when `loading` prop is `false`', () => {
    it('displays total egress data used', () => {
      createComponent();

      expect(wrapper.findByTestId('total-egress').text()).toBe('13.53 MiB');
    });

    it('renders `SectionedPercentageBar` and passes correct props', () => {
      createComponent();

      expect(findSectionedPercentageBar().props('sections')).toEqual([
        expect.objectContaining({
          id: EGRESS_TYPE_ARTIFACTS,
          label: __('Artifacts'),
          value: 4029020,
          formattedValue: '3.84 MiB',
        }),
        expect.objectContaining({
          id: EGRESS_TYPE_REPOSITORY,
          label: __('Repository'),
          value: 3276391,
          formattedValue: '3.12 MiB',
        }),
        expect.objectContaining({
          id: EGRESS_TYPE_PACKAGES,
          label: __('Packages'),
          value: 4096992,
          formattedValue: '3.91 MiB',
        }),
        expect.objectContaining({
          id: EGRESS_TYPE_REGISTRY,
          label: s__('UsageQuota|Registry'),
          value: 2780286,
          formattedValue: '2.65 MiB',
        }),
      ]);
    });

    describe('when egress total is 0', () => {
      it('does not render `SectionedPercentageBar`', () => {
        createComponent({
          propsData: {
            egressNodes: [
              {
                totalEgress: '0',
                repositoryEgress: '0',
                artifactsEgress: '0',
                packagesEgress: '0',
                registryEgress: '0',
                __typename: 'EgressNode',
              },
            ],
          },
        });

        expect(findSectionedPercentageBar().exists()).toBe(false);
      });
    });

    describe('when egress type is 0', () => {
      it('does not pass that egress type to `SectionedPercentageBar`', () => {
        createComponent({
          propsData: {
            egressNodes: [
              {
                totalEgress: '693354',
                repositoryEgress: '0',
                artifactsEgress: '384262',
                packagesEgress: '273801',
                registryEgress: '35291',
                __typename: 'EgressNode',
              },
            ],
          },
        });

        expect(
          findSectionedPercentageBar()
            .props('sections')
            .find((section) => section.id === EGRESS_TYPE_REPOSITORY),
        ).toBeUndefined();
      });
    });

    describe('egress type table', () => {
      describe('Transfer type column', () => {
        describe.each`
          rowIndex | expectedIcon                 | expectedLabelAndDescription                                                          | expectedHelpPath
          ${0}     | ${'disk'}                    | ${'Artifacts Pipeline artifacts and job artifacts, created with CI/CD.'}             | ${'/help/ci/caching/index#artifacts'}
          ${1}     | ${'infrastructure-registry'} | ${'Repository Git repository.'}                                                      | ${'/help/user/project/repository/reducing_the_repo_size_using_git'}
          ${2}     | ${'package'}                 | ${'Packages Code packages and container images.'}                                    | ${'/help/user/packages/package_registry/index'}
          ${3}     | ${'disk'}                    | ${'Registry Gitlab-integrated Docker Container Registry for storing Docker Images.'} | ${'/help/user/packages/container_registry/reduce_container_registry_storage'}
        `(
          'row index $rowIndex',
          ({ rowIndex, expectedIcon, expectedLabelAndDescription, expectedHelpPath }) => {
            let cell;

            beforeEach(() => {
              createComponent();

              cell = wrapper.findAllByTestId('transfer-type-column').at(rowIndex);
            });

            it('renders icon', () => {
              expect(cell.findComponent(GlIcon).props('name')).toEqual(expectedIcon);
            });

            it('renders label and description', () => {
              expect(cell.text()).toMatchInterpolatedText(expectedLabelAndDescription);
            });

            it('renders help link', () => {
              expect(cell.findComponent(GlLink).attributes('href')).toBe(expectedHelpPath);
            });
          },
        );
      });

      describe('Usage column', () => {
        describe.each`
          rowIndex | expectedUsage
          ${0}     | ${'3.84 MiB'}
          ${1}     | ${'3.12 MiB'}
          ${2}     | ${'3.91 MiB'}
          ${3}     | ${'2.65 MiB'}
        `('row index $rowIndex', ({ rowIndex, expectedUsage }) => {
          let cell;

          beforeEach(() => {
            createComponent();

            cell = wrapper.findAllByTestId('usage-column').at(rowIndex);
          });

          it('renders usage', () => {
            createComponent();

            expect(cell.text()).toBe(expectedUsage);
          });
        });
      });
    });
  });
});
