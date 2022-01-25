import { GlSearchBoxByType } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';

const findSidebarEditableItem = (wrapper) => wrapper.findComponent(SidebarEditableItem);
const findEditButton = (wrapper) =>
  findSidebarEditableItem(wrapper).find('[data-testid="edit-button"]');
const findSearchBox = (wrapper) => wrapper.findComponent(GlSearchBoxByType);

export const search = async (wrapper, searchTerm) => {
  findSearchBox(wrapper).vm.$emit('input', searchTerm);

  await waitForPromises();
  jest.runAllTimers(); // Account for debouncing
};

// Used with createComponentWithApollo which uses 'mount'
export const clickEdit = async (wrapper) => {
  await findEditButton(wrapper).trigger('click');

  // We should wait for attributes list to be fetched.
  jest.runAllTimers();
  await waitForPromises();
};
