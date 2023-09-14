import { GlAccordionItem, GlFormCheckbox, GlLink, GlSprintf } from '@gitlab/ui';
import SettingsItem from 'ee/security_orchestration/components/policy_editor/scan_result_policy/settings/settings_item.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { NAMESPACE_TYPES } from 'ee/security_orchestration/constants';

describe('SettingsItem', () => {
  let wrapper;

  const createComponent = ({ propsData = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(SettingsItem, {
      propsData: {
        title: 'Test title',
        link: 'test-path',
        settings: {
          test: { enabled: true },
          test1: { enabled: false },
        },
        ...propsData,
      },
      provide: {
        namespaceType: NAMESPACE_TYPES.PROJECT,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findAllCheckBoxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findAccordionItem = () => wrapper.findComponent(GlAccordionItem);
  const findDescriptionText = () => wrapper.findByTestId('settings-group-text');
  const findDescriptionLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    createComponent();
  });

  it('should render checkboxes based on settings', () => {
    expect(findAccordionItem().props('title')).toBe('Test title');
    expect(findAllCheckBoxes()).toHaveLength(2);
    expect(findAllCheckBoxes().at(0).attributes('checked')).toBe('true');
    expect(findAllCheckBoxes().at(1).attributes('checked')).toBeUndefined();
  });

  it('emits selected setting when updated', () => {
    findAllCheckBoxes().at(0).vm.$emit('change', true);

    expect(wrapper.emitted('update')).toEqual([[{ key: 'test', value: true }]]);
  });

  it('should not display link if no link is provided', () => {
    createComponent({
      propsData: {
        description: '%{linkStart}project settings%{linkEnd}',
        link: '',
      },
    });

    expect(findDescriptionLink().exists()).toBe(false);
    expect(findDescriptionText().exists()).toBe(true);
  });

  it.each`
    namespaceType              | linkVisible | textVisible
    ${NAMESPACE_TYPES.PROJECT} | ${true}     | ${false}
    ${NAMESPACE_TYPES.GROUP}   | ${false}    | ${true}
  `('should render elements for namespace type', ({ namespaceType, linkVisible, textVisible }) => {
    createComponent({
      propsData: {
        description: '%{linkStart}project settings%{linkEnd}',
      },
      provide: { namespaceType },
    });

    expect(findDescriptionLink().exists()).toBe(linkVisible);
    expect(findDescriptionText().exists()).toBe(textVisible);
  });
});
