import { nextTick } from 'vue';
import { GlSearchBoxByType } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';

const findSidebarEditableItem = (wrapper) => wrapper.findComponent(SidebarEditableItem);
const findEditButton = (wrapper) =>
  findSidebarEditableItem(wrapper).find('[data-testid="edit-button"]');
const findSearchBox = (wrapper) => wrapper.findComponent(GlSearchBoxByType);

export const search = async (wrapper, searchTerm) => {
  findSearchBox(wrapper).vm.$emit('input', searchTerm);

  await nextTick();
  jest.runAllTimers(); // Account for debouncing
};

export const waitForDropdown = async () => {
  // BDropdown first changes its `visible` property
  // in a requestAnimationFrame callback.
  // It then emits `shown` event in a watcher for `visible`
  // Hence we need both of these:
  await waitForPromises();

  await nextTick();
};

export const waitForApollo = async () => {
  jest.runOnlyPendingTimers();
  await waitForPromises();
};

// Used with createComponentWithApollo which uses 'mount'
export const clickEdit = async (wrapper) => {
  await findEditButton(wrapper).trigger('click');

  await waitForDropdown(wrapper);

  // We should wait for attributes list to be fetched.
  await waitForApollo();
};
