import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { STATUSES } from '~/import_entities/constants';
import ImportActionsCell from '~/import_entities/import_groups/components/import_actions_cell.vue';
import { generateFakeEntry } from '../graphql/fixtures';

describe('import actions cell', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(ImportActionsCell, {
      propsData: {
        groupPathRegex: /^[a-zA-Z]+$/,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders import button when group status is NONE', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.NONE });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    console.log(wrapper.html());
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Import');
  });

  it('renders re-import button when group status is FINISHED', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.FINISHED });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Re-import');
  });

  it('does not render import button when group import is in progress', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.STARTED });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    expect(button.exists()).toBe(false);
  });

  it('emits import-group event when import button is clicked', () => {
    const group = generateFakeEntry({ id: 1, status: STATUSES.NONE });
    createComponent({ group });

    const button = wrapper.findComponent(GlButton);
    button.vm.$emit('click');

    expect(wrapper.emitted('import-group')).toHaveLength(1);
  });
});
