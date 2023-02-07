import { GlAvatar, GlButton } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { sprintf, s__ } from '~/locale';
import { createStore } from 'ee/protected_environments/store/edit';
import EditProtectedEnvironmentsList from 'ee/protected_environments/edit_protected_environments_list.vue';
import { MAINTAINER_ACCESS_LEVEL, DEVELOPER_ACCESS_LEVEL } from './constants';

const DEFAULT_ENVIRONMENTS = [
  {
    name: 'staging',
    deploy_access_levels: [
      {
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        group_id: null,
        user_id: null,
      },
      {
        group_id: 1,
        group_inheritance_type: '1',
        access_level_description: 'Some group',
        access_level: null,
        user_id: null,
      },
      { user_id: 1, access_level_description: 'Some user', access_level: null, group_id: null },
    ],
  },
];

const DEFAULT_PROJECT_ID = '8';

Vue.use(Vuex);

describe('ee/protected_environments/edit_protected_environments_list.vue', () => {
  let store;
  let wrapper;
  let mock;
  let originalGon;

  const createComponent = async () => {
    store = createStore({ projectId: DEFAULT_PROJECT_ID });

    wrapper = mountExtended(EditProtectedEnvironmentsList, {
      store,
    });

    await waitForPromises();
    await nextTick();
  };

  const findDeleteButton = () =>
    wrapper.findByTitle(s__('ProtectedEnvironments|Delete deployment rule'));

  beforeEach(() => {
    mock = new MockAdapter(axios);
    originalGon = window.gon;
    window.gon = { api_version: 'v4' };
    mock
      .onGet('/api/v4/projects/8/protected_environments/')
      .reply(HTTP_STATUS_OK, DEFAULT_ENVIRONMENTS);
    mock
      .onGet('/api/v4/groups/1/members/all')
      .reply(HTTP_STATUS_OK, [{ name: 'root', avatar_url: '/avatar.png' }]);
    mock
      .onGet('/api/v4/users/1')
      .reply(HTTP_STATUS_OK, { name: 'root', avatar_url: '/avatar.png' });
    mock.onGet('/api/v4/projects/8/members').reply(HTTP_STATUS_OK, [
      {
        name: 'root',
        access_level: MAINTAINER_ACCESS_LEVEL.toString(),
        avatar_url: '/avatar.png',
      },
    ]);
  });

  afterEach(() => {
    mock.restore();
    mock.resetHistory();
    window.gon = originalGon;
  });

  it('shows a header counting the number of protected environments', async () => {
    await createComponent();

    expect(
      wrapper
        .findByRole('heading', {
          name: sprintf(
            s__(
              'ProtectedEnvironments|List of protected environments (%{protectedEnvironmentsCount})',
            ),
            { protectedEnvironmentsCount: 1 },
          ),
        })
        .exists(),
    ).toBe(true);
  });

  it('shows a header for the protected environment', async () => {
    await createComponent();

    expect(wrapper.findByRole('heading', { name: 'staging' }).exists()).toBe(true);
  });

  it('shows member avatars in each row', async () => {
    await createComponent();

    const avatars = wrapper.findAllComponents(GlAvatar).wrappers;

    expect(avatars).toHaveLength(3);
    avatars.forEach((avatar) => expect(avatar.props('src')).toBe('/avatar.png'));
  });

  it('shows the description of the rule', async () => {
    const [{ deploy_access_levels: deployAccessLevels }] = DEFAULT_ENVIRONMENTS;
    await createComponent();

    const descriptions = wrapper.findAllByTestId('rule-description').wrappers;

    descriptions.forEach((description, i) => {
      expect(description.text()).toBe(deployAccessLevels[i].access_level_description);
    });
  });

  describe('delete rule', () => {
    it('sends the deleted rule with _destroy set', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;

      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      const button = findDeleteButton();

      mock.onPut().reply(HTTP_STATUS_OK);

      const destroyedRule = {
        access_level: DEVELOPER_ACCESS_LEVEL,
        access_level_description: 'Deployers + Maintainers',
        _destroy: true,
      };

      button.trigger('click');

      await waitForPromises();

      expect(mock.history.put.length).toBe(1);

      const [{ data }] = mock.history.put;
      expect(JSON.parse(data)).toMatchObject({
        ...environment,
        deploy_access_levels: [destroyedRule],
      });
    });

    it('hides the button if there is only one rule', async () => {
      const [environment] = DEFAULT_ENVIRONMENTS;
      const [rule] = environment.deploy_access_levels;
      mock.onGet('/api/v4/projects/8/protected_environments/').reply(HTTP_STATUS_OK, [
        {
          ...environment,
          deploy_access_levels: [rule],
        },
      ]);

      await createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click');

      const button = findDeleteButton();

      expect(button.exists()).toBe(false);
    });
  });
});
