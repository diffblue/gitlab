import { getByTestId as getByTestIdHelper, within } from '@testing-library/dom';
import { createWrapper, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import CveIdRequest from 'ee/sidebar/components/cve_id_request/cve_id_request.vue';
import { store } from '~/notes/stores';

describe('CveIdRequest', () => {
  let wrapper;

  const provide = {
    iid: 'test',
    fullPath: 'some/path',
    issueTitle: 'Issue Title',
  };

  const createComponent = () => {
    wrapper = shallowMount(CveIdRequest, {
      provide,
      store,
    });
  };

  const getByTestId = (id, options) =>
    createWrapper(getByTestIdHelper(wrapper.element, id, options));
  const queryByTestId = (id, options) => within(wrapper.element).queryByTestId(id, options);

  beforeEach(() => {
    store.state.noteableData.confidential = true;

    createComponent();
  });

  it('Renders the main "Request CVE ID" button', () => {
    expect(getByTestId('request-button').exists()).toBe(true);
  });

  it('Renders the "help-button" by default', () => {
    expect(getByTestId('help-button').exists()).toBe(true);
  });

  describe('Help Pane', () => {
    const findHelpButton = () => getByTestId('help-button');
    const findCloseHelpButton = () => getByTestId('close-help-button');
    const queryHelpPane = () => queryByTestId('help-state');

    beforeEach(() => {
      createComponent();
    });

    it('should not show the "Help" pane by default', () => {
      expect(wrapper.vm.showHelpState).toBe(false);
      expect(queryHelpPane()).toBe(null);
    });

    it('should show the "Help" pane when help button is clicked', async () => {
      findHelpButton().trigger('click');

      await nextTick();
      expect(wrapper.vm.showHelpState).toBe(true);

      // let animations run
      jest.advanceTimersByTime(500);

      expect(queryHelpPane()).not.toBe(null);
    });

    it('should not show the "Help" pane when help button is clicked and then closed', async () => {
      findHelpButton().trigger('click');

      await nextTick();

      findCloseHelpButton().trigger('click');
      await nextTick();

      expect(wrapper.vm.showHelpState).toBe(false);
      expect(queryHelpPane()).toBe(null);
    });
  });
});
