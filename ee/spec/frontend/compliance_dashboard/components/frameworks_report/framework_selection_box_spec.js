import { GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { mount, ErrorWrapper } from '@vue/test-utils';
import { captureException } from '@sentry/browser';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import { createAlert } from '~/alert';
import { validFetchResponse as getComplianceFrameworksResponse } from 'ee_jest/groups/settings/compliance_frameworks/mock_data';
import FrameworkSelectionBox from 'ee/compliance_dashboard/components/frameworks_report/framework_selection_box.vue';

import getComplianceFrameworkQuery from 'ee/graphql_shared/queries/get_compliance_framework.query.graphql';

jest.mock('@sentry/browser');
jest.mock('~/alert');

Vue.use(VueApollo);
describe('FrameworkSelectionBox component', () => {
  let wrapper;
  let apolloProvider;
  const getComplianceFrameworkQueryResponse = jest
    .fn()
    .mockResolvedValue(getComplianceFrameworksResponse);

  const findNewFrameworkButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find((w) => w.text().includes(FrameworkSelectionBox.i18n.createNewFramework)) ??
    new ErrorWrapper();

  const createComponent = (props) => {
    apolloProvider = createMockApollo([
      [getComplianceFrameworkQuery, getComplianceFrameworkQueryResponse],
    ]);

    wrapper = mount(FrameworkSelectionBox, {
      apolloProvider,
      propsData: {
        rootAncestorPath: 'group-path',
        ...props,
      },
    });
  };

  beforeEach(() => {
    getComplianceFrameworkQueryResponse.mockClear();
  });

  it('sets underlying listbox as disabled when disabled prop is true', () => {
    createComponent({ disabled: true });

    expect(wrapper.findComponent(GlCollapsibleListbox).props('disabled')).toBe(true);
  });

  it('sets toggle-text as default one when selection is not provided', () => {
    createComponent();
    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(
      FrameworkSelectionBox.i18n.frameworksDropdownPlaceholder,
    );
  });

  it('sets toggle-text to framework name when it matches selection', async () => {
    const framework = getComplianceFrameworksResponse.data.namespace.complianceFrameworks.nodes[0];
    createComponent({ selected: framework.id });
    await waitForPromises();

    expect(wrapper.findComponent(GlCollapsibleListbox).props('toggleText')).toBe(framework.name);
  });

  it('emits selected framework from underlying listbox', () => {
    createComponent();

    wrapper.findComponent(GlCollapsibleListbox).vm.$emit('select', 'framework-id');
    expect(wrapper.emitted('select').at(-1)).toStrictEqual(['framework-id']);
  });

  it('filters framework list for underlying listbox', async () => {
    createComponent();
    await waitForPromises();

    wrapper.findComponent(GlCollapsibleListbox).vm.$emit('search', 'PCI');
    await nextTick();

    // only "PCI-DSS" from fixture matches
    expect(wrapper.findComponent(GlCollapsibleListbox).props('items')).toHaveLength(1);
  });

  it('sets listbox to loading while loading list of elements', () => {
    createComponent();
    expect(wrapper.findComponent(GlCollapsibleListbox).props('loading')).toBe(true);
  });

  it('reports error to sentry', async () => {
    const ERROR = new Error('Network error');
    getComplianceFrameworkQueryResponse.mockRejectedValue(ERROR);
    createComponent();
    await waitForPromises();

    expect(captureException).toHaveBeenCalledWith(ERROR);
    expect(createAlert).toHaveBeenCalled();
  });

  it('has a new framework button', () => {
    createComponent();

    expect(findNewFrameworkButton().exists()).toBe(true);
  });

  it('clicking new framework button emits create event', () => {
    createComponent();
    findNewFrameworkButton().vm.$emit('click');

    expect(wrapper.emitted('create')).toHaveLength(1);
  });
});
