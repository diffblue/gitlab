import { shallowMount } from '@vue/test-utils';
import ForkSuggestion from '~/repository/components/fork_suggestion.vue';

const DEFAULT_PROPS = { forkPath: 'some_file.js/fork' };

describe('ForkSuggestion component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ForkSuggestion, {
      propsData: { ...DEFAULT_PROPS },
    });
  };

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  const findMessage = () => wrapper.find('[data-testid="message"]');
  const findForkButton = () => wrapper.find('[data-testid="fork"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel"]');

  it('renders a message', () => {
    expect(findMessage().exists()).toBe(true);
    expect(findMessage().text()).toBe(
      'You can’t edit files directly in this project. Fork this project and submit a merge request with your changes.',
    );
  });

  it('renders component', () => {
    const { forkPath } = DEFAULT_PROPS;

    expect(wrapper.props()).toMatchObject({ forkPath });
  });

  it('renders a Fork button', () => {
    expect(findForkButton().exists()).toBe(true);
    expect(findForkButton().text()).toBe('Fork');
    expect(findForkButton().attributes('href')).toBe(DEFAULT_PROPS.forkPath);
  });

  it('renders a Cancel button', () => {
    expect(findCancelButton().exists()).toBe(true);
    expect(findCancelButton().text()).toBe('Cancel');
  });

  it('emits a cancel event when Cancel button is clicked', () => {
    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });
});
