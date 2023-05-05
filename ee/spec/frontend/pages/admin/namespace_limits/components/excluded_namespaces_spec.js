import { shallowMount } from '@vue/test-utils';
import { GlTable, GlButton } from '@gitlab/ui';
import ExcludedNamespaces from 'ee/pages/admin/namespace_limits/components/excluded_namespaces.vue';

describe('ExcludedNamespaces', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ExcludedNamespaces);
  };

  const findTable = () => wrapper.findComponent(GlTable);

  describe('rendering components', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the excluded namespaces table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders placeholder for the form', () => {
      expect(wrapper.text()).toContain('Exclusion form placeholder');
    });

    it('marks the table as busy when loading is true', async () => {
      expect(findTable().attributes('busy')).toBeUndefined();
      await wrapper.findComponent(GlButton).vm.$emit('click');
      expect(findTable().attributes('busy')).toBe('true');
    });
  });
});
