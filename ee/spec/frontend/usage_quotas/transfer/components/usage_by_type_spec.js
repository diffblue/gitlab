import { GlSkeletonLoader, GlTableLite, GlIcon, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsageByType from 'ee/usage_quotas/transfer/components/usage_by_type.vue';
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
  const percentageBarTestidPrefix = 'percentage-bar-egress-type-';
  const percentageBarLegendTestidPrefix = 'percentage-bar-legend-egress-type-';

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

    it('displays egress type percentage bar', () => {
      createComponent();

      const artifacts = wrapper.findByTestId(percentageBarTestidPrefix + EGRESS_TYPE_ARTIFACTS);
      const repository = wrapper.findByTestId(percentageBarTestidPrefix + EGRESS_TYPE_REPOSITORY);
      const packages = wrapper.findByTestId(percentageBarTestidPrefix + EGRESS_TYPE_PACKAGES);
      const registry = wrapper.findByTestId(percentageBarTestidPrefix + EGRESS_TYPE_REGISTRY);

      expect(artifacts.attributes('style')).toBe('width: 28.408%;');
      expect(repository.attributes('style')).toBe('width: 23.1013%;');
      expect(packages.attributes('style')).toBe('width: 28.8873%;');
      expect(registry.attributes('style')).toBe('width: 19.6034%;');
      expect(artifacts.text()).toMatchInterpolatedText('Artifacts 28.4%');
      expect(repository.text()).toMatchInterpolatedText('Repository 23.1%');
      expect(packages.text()).toMatchInterpolatedText('Packages 28.9%');
      expect(registry.text()).toMatchInterpolatedText('Registry 19.6%');
    });

    it('displays egress type percentage bar legend', () => {
      createComponent();

      const artifacts = wrapper.findByTestId(
        percentageBarLegendTestidPrefix + EGRESS_TYPE_ARTIFACTS,
      );
      const repository = wrapper.findByTestId(
        percentageBarLegendTestidPrefix + EGRESS_TYPE_REPOSITORY,
      );
      const packages = wrapper.findByTestId(percentageBarLegendTestidPrefix + EGRESS_TYPE_PACKAGES);
      const registry = wrapper.findByTestId(percentageBarLegendTestidPrefix + EGRESS_TYPE_REGISTRY);

      expect(artifacts.text()).toMatchInterpolatedText('Artifacts 3.84 MiB');
      expect(repository.text()).toMatchInterpolatedText('Repository 3.12 MiB');
      expect(packages.text()).toMatchInterpolatedText('Packages 3.91 MiB');
      expect(registry.text()).toMatchInterpolatedText('Registry 2.65 MiB');
    });

    describe('when egress total is 0', () => {
      it('does not display percentage bar', () => {
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

        expect(wrapper.findByTestId('percentage-bar').exists()).toBe(false);
      });
    });

    describe('when egress type is 0', () => {
      it('does not display that egress type in percentage bar', () => {
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

        expect(wrapper.findByTestId('percentage-bar').exists()).toBe(true);
        expect(
          wrapper.findByTestId(percentageBarTestidPrefix + EGRESS_TYPE_REPOSITORY).exists(),
        ).toBe(false);
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
