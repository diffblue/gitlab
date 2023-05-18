import { shallowMount } from '@vue/test-utils';
import { GlTable } from '@gitlab/ui';
import ExcludedNamespaces from 'ee/pages/admin/namespace_limits/components/excluded_namespaces.vue';
import ExcludedNamespacesForm from 'ee/pages/admin/namespace_limits/components/excluded_namespaces_form.vue';

describe('ExcludedNamespaces', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ExcludedNamespaces);
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findForm = () => wrapper.findComponent(ExcludedNamespacesForm);

  describe('rendering components', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the excluded namespaces table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('renders excluded namespaces form', () => {
      expect(findForm().exists()).toBe(true);
    });

    it('marks the table as busy when loading is true', async () => {
      expect(findTable().attributes('busy')).toBeUndefined();
      await findForm().vm.$emit('added');
      expect(findTable().attributes('busy')).toBe('true');
    });
  });
});
