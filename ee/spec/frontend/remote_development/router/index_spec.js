import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import App from 'ee/remote_development/pages/app.vue';
import WorkspacesList from 'ee/remote_development/pages/list.vue';
import createRouter from 'ee/remote_development/router/index';
import createMockApollo from 'helpers/mock_apollo_helper';

Vue.use(VueRouter);
Vue.use(VueApollo);

const SVG_PATH = '/assets/illustrations/empty_states/empty_workspaces.svg';

describe('remote_development/router/index.js', () => {
  let router;

  beforeEach(() => {
    router = createRouter('/');
    jest.spyOn(router, 'push').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
    window.location.hash = '';
  });

  it('renders WorkspacesList on route /', async () => {
    const wrapper = mount(App, {
      apolloProvider: createMockApollo(),
      router,
      provide: {
        emptyStateSvgPath: SVG_PATH,
      },
    });

    await router.push('/');

    expect(wrapper.findComponent(WorkspacesList).exists()).toBe(true);
  });
});
