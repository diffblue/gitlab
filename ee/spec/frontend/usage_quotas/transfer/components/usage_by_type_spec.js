import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
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
    wrapper = shallowMountExtended(UsageByType, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

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
  });
});
