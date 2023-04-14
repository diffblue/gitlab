import { GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CardShowcase from 'ee/vue_shared/showcase/card_showcase.vue';

describe('Card Showcase component', () => {
  const propsData = {
    title: 'My title',
    description: 'A description',
    primaryAction: 'Primary action',
    primaryLink: 'http://example.org/primary',
    primaryLinkIcon: 'external-link',
    secondaryAction: 'Secondary action',
    secondaryLink: 'http://example.org/secondary',
  };
  let wrapper;
  const findGlCard = () => wrapper.findComponent(GlCard);
  const findPrimaryButton = () => wrapper.findByTestId('primary-button');
  const findSecondaryButton = () => wrapper.findByTestId('secondary-button');

  const createWrapper = () => {
    wrapper = shallowMountExtended(CardShowcase, {
      propsData: {
        ...propsData,
      },
    });
  };

  it('renders correctly', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders card title and description', () => {
    createWrapper();

    expect(findGlCard().html()).toContain(propsData.title);
    expect(findGlCard().html()).toContain(propsData.description);
  });

  it('renders primary button', () => {
    createWrapper();

    expect(findPrimaryButton().props()).toMatchObject({
      category: 'primary',
      variant: 'confirm',
      target: '_blank',
    });
  });

  it('renders secondary button', () => {
    createWrapper();

    expect(findSecondaryButton().props()).toMatchObject({
      category: 'secondary',
      variant: 'confirm',
      target: '_blank',
    });
  });
});
