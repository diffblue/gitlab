import { GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import ContainerRegistryUsage from 'ee/usage_quotas/storage/components/container_registry_usage.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';

describe('Container registry usage component', () => {
  let wrapper;

  const helpPath = helpPagePath('user/packages/container_registry/index');
  const defaultProps = {
    containerRegistrySize: 512,
  };

  const findTotalSizeSection = () => wrapper.findByTestId('total-size-section');
  const findMoreInformation = () => wrapper.findByTestId('container-registry-description');

  const createComponent = () => {
    wrapper = shallowMountExtended(ContainerRegistryUsage, {
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

  it('displays the total size section when prop is provided', () => {
    const expectedValue = numberToHumanSize(defaultProps.containerRegistrySize, 1);

    expect(findTotalSizeSection().text()).toBe(expectedValue);
  });

  it('displays a description and more information link', () => {
    const moreInformationComponent = findMoreInformation();

    expect(moreInformationComponent.text()).toBe(
      'Gitlab-integrated Docker Container Registry for storing Docker Images. More information',
    );
    expect(moreInformationComponent.findComponent(GlLink).attributes('href')).toBe(helpPath);
  });
});
