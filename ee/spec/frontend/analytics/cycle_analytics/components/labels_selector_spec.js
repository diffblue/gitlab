import { GlDropdownSectionHeader } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import LabelsSelector from 'ee/analytics/cycle_analytics/components/labels_selector.vue';
import createStore from 'ee/analytics/cycle_analytics/store';
import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash from '~/flash';
import { groupLabels } from '../mock_data';

jest.mock('~/flash');
Vue.use(Vuex);

const selectedLabel = groupLabels[groupLabels.length - 1];
const findActiveItem = (wrapper) =>
  wrapper
    .findAll('gl-dropdown-item-stub')
    .filter((d) => d.attributes('active'))
    .at(0);

const mockGroupLabelsRequest = (status = 200) =>
  new MockAdapter(axios).onGet().reply(status, groupLabels);

describe('Value Stream Analytics LabelsSelector', () => {
  let store = null;

  function createComponent({ props = { selectedLabelIds: [] }, shallow = true } = {}) {
    store = createStore();
    const func = shallow ? shallowMount : mount;
    return func(LabelsSelector, {
      store: {
        ...store,
        getters: {
          ...getters,
          currentGroupPath: 'fake',
        },
      },
      propsData: {
        ...props,
      },
    });
  }

  let wrapper = null;
  let mock = null;
  const labelNames = groupLabels.map(({ name }) => name);

  describe('with no item selected', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({});

      return waitForPromises();
    });

    afterEach(() => {
      mock.restore();
      wrapper.destroy();
      wrapper = null;
    });

    it('will render the label selector', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it.each(labelNames)('generate a label item for the label %s', (name) => {
      expect(wrapper.text()).toContain(name);
    });

    it('will fetch the labels', () => {
      expect(mock.history.get.length).toBe(1);
    });

    it('will render with the default option selected', () => {
      const sectionHeader = wrapper.findComponent(GlDropdownSectionHeader);

      expect(sectionHeader.exists()).toBe(true);
      expect(sectionHeader.text()).toEqual('Select a label');
    });

    describe('with a failed request', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest(404);
        wrapper = createComponent({});

        return waitForPromises();
      });

      it('should flash an error message', () => {
        expect(createFlash).toHaveBeenCalledWith({
          message: 'There was an error fetching label data for the selected group',
        });
      });
    });

    describe('when a dropdown item is clicked', () => {
      beforeEach(() => {
        mock = mockGroupLabelsRequest();
        wrapper = createComponent({ shallow: false });
        return waitForPromises();
      });

      it('will emit the "select-label" event', async () => {
        expect(wrapper.emitted('select-label')).toBeUndefined();

        const elem = wrapper.findAll('.dropdown-item').at(1);
        elem.trigger('click');

        await nextTick();
        expect(wrapper.emitted('select-label').length > 0).toBe(true);
        expect(wrapper.emitted('select-label')[0]).toContain(groupLabels[1].id);
      });
    });
  });

  describe('with selectedLabelIds set', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({ props: { selectedLabelIds: [selectedLabel.id] } });
      return waitForPromises();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will render the label selector', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    it('will set the active label', () => {
      const activeItem = findActiveItem(wrapper);

      expect(activeItem.exists()).toBe(true);
      expect(activeItem.text()).toEqual(selectedLabel.name);
    });
  });

  describe('with labels provided', () => {
    beforeEach(() => {
      mock = mockGroupLabelsRequest();
      wrapper = createComponent({ props: { initialData: groupLabels } });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('will not fetch the labels', () => {
      expect(mock.history.get.length).toBe(0);
    });
  });
});
