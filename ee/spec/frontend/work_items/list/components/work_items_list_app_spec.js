import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CreateWorkItemForm from 'ee/work_items/components/create_work_item_form.vue';
import EEWorkItemsListApp from 'ee/work_items/list/components/work_items_list_app.vue';

describe('WorkItemsListApp EE component', () => {
  let wrapper;

  const findCreateWorkItemForm = () => wrapper.findComponent(CreateWorkItemForm);
  const findGlButton = () => wrapper.findComponent(GlButton);

  const mountComponent = ({ hasEpicsFeature = false } = {}) => {
    wrapper = shallowMount(EEWorkItemsListApp, {
      provide: {
        hasEpicsFeature,
      },
    });
  };

  describe('when epics feature is available', () => {
    beforeEach(() => {
      mountComponent({ hasEpicsFeature: true });
    });

    it('renders "Create epic" button', () => {
      expect(findGlButton().text()).toBe('Create epic');
    });

    it('does not render "Create epic" form initially', () => {
      expect(findCreateWorkItemForm().exists()).toBe(false);
    });

    describe('when "Create epic" button is clicked', () => {
      beforeEach(() => {
        findGlButton().vm.$emit('click');
      });

      it('renders "Create epic" form', () => {
        expect(findCreateWorkItemForm().props()).toEqual({
          isGroup: true,
          workItemType: 'Epic',
        });
      });

      it('hides form when "hide" event is emitted', async () => {
        findCreateWorkItemForm().vm.$emit('hide');
        await nextTick();

        expect(findCreateWorkItemForm().exists()).toBe(false);
      });
    });
  });

  describe('when epics feature is not available', () => {
    beforeEach(() => {
      mountComponent({ hasEpicsFeature: false });
    });

    it('does not render "Create epic" button', () => {
      expect(findGlButton().exists()).toBe(false);
    });

    it('does not render "Create epic" form', () => {
      expect(findCreateWorkItemForm().exists()).toBe(false);
    });
  });
});
