import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import DependencyProxyUsage from 'ee/usage_quotas/storage/components/dependency_proxy_usage.vue';

describe('Dependency proxy usage component', () => {
  let wrapper;

  const helpPath = helpPagePath('user/usage_quotas');
  const defaultProps = {
    dependencyProxyTotalSize: '512 bytes',
  };

  const findTotalSizeSection = () => wrapper.findByTestId('total-size-section');
  const findMoreInformation = () => wrapper.findByTestId('dependency-proxy-description');

  const createComponent = () => {
    wrapper = shallowMountExtended(DependencyProxyUsage, {
      propsData: {
        ...defaultProps,
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

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the total size section when prop is provided', () => {
    expect(findTotalSizeSection().text()).toBe(defaultProps.dependencyProxyTotalSize);
  });

  it('displays a more information link', () => {
    const moreInformationComponent = findMoreInformation();

    expect(moreInformationComponent.text()).toBe(
      'Local proxy used for frequently-accessed upstream Docker images. More information',
    );
    expect(moreInformationComponent.findComponent(GlLink).attributes('href')).toBe(helpPath);
  });
});
