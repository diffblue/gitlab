import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import DependencyProxyUsage from 'ee/usage_quotas/storage/components/dependency_proxy_usage.vue';

describe('Dependency proxy usage component', () => {
  let wrapper;

  const helpPath = helpPagePath('user/packages/dependency_proxy/index');
  const defaultProps = {
    dependencyProxyTotalSize: '512',
  };

  const findDependencyProxySizeSection = () => wrapper.findByTestId('dependency-proxy-size');
  const findMoreInformation = () => wrapper.findByTestId('dependency-proxy-description');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DependencyProxyUsage, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlSprintf,
        GlLink,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays the dependency proxy size section when prop is provided', () => {
    expect(findDependencyProxySizeSection().props('value')).toBe(512);
  });

  describe('when `dependencyProxyTotalSize` has BigInt value', () => {
    const mockDependencyProxyTotalSize = String(Number.MAX_SAFE_INTEGER);

    beforeEach(() => {
      createComponent({
        props: {
          dependencyProxyTotalSize: mockDependencyProxyTotalSize,
        },
      });
    });

    it('displays the dependency proxy size section when prop is provided', () => {
      expect(findDependencyProxySizeSection().props('value')).toBe(Number.MAX_SAFE_INTEGER);
    });
  });

  it('displays a more information link', () => {
    const moreInformationComponent = findMoreInformation();

    expect(moreInformationComponent.text()).toBe(
      'Local proxy used for frequently-accessed upstream Docker images. More information',
    );
    expect(moreInformationComponent.findComponent(GlLink).attributes('href')).toBe(helpPath);
  });
});
