import { mount } from '@vue/test-utils';
import WelcomePage from '~/vue_shared/new_namespace/components/welcome.vue';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';

describe('Experimental new project creation app', () => {
  let wrapper;

  const findWelcomePage = () => wrapper.findComponent(WelcomePage);

  const DEFAULT_PROPS = {
    title: 'Create something',
    initialBreadcrumbs: [{ text: 'Something', href: '#' }],
    panels: [
      { name: 'panel1', selector: '#some-selector1' },
      { name: 'panel2', selector: '#some-selector2' },
    ],
    persistenceKey: 'DEMO-PERSISTENCE-KEY',
  };

  const createComponent = () => {
    wrapper = mount(NewNamespacePage, {
      propsData: DEFAULT_PROPS,
    });
  };

  it('shows welcome page', () => {
    createComponent();
    expect(findWelcomePage().exists()).toBe(true);
  });
});
