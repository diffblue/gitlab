import { shallowMount } from '@vue/test-utils';
import EpicHeader from 'ee/epic/components/epic_header.vue';
import createStore from 'ee/epic/store';
import IssuableHeader from '~/vue_shared/issuable/show/components/issuable_header.vue';
import { mockEpicMeta } from '../mock_data';

describe('EpicHeader component', () => {
  let wrapper;

  const createComponent = () => {
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    wrapper = shallowMount(EpicHeader, {
      propsData: {
        formattedAuthor: { id: '1', name: 'Arthur', username: 'arthur' },
      },
      store,
    });
  };

  const findIssuableHeader = () => wrapper.findComponent(IssuableHeader);

  beforeEach(() => {
    createComponent();
  });

  it('renders IssuableHeader component', () => {
    expect(findIssuableHeader().props()).toMatchObject({
      confidential: false,
      createdAt: '2015-07-03T10:00:00.000Z',
      issuableState: 'opened',
      issuableType: 'epic',
      statusIcon: 'epic',
      workspaceType: 'group',
    });
  });
});
