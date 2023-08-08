import { shallowMount } from '@vue/test-utils';
import EpicBody from 'ee/epic/components/epic_body.vue';
import EpicHeader from 'ee/epic/components/epic_header.vue';
import EpicHeaderActions from 'ee/epic/components/epic_header_actions.vue';
import createStore from 'ee/epic/store';
import IssuableBody from '~/issues/show/components/app.vue';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicBodyComponent', () => {
  let wrapper;

  const findEpicHeader = () => wrapper.findComponent(EpicHeader);
  const findEpicHeaderActions = () => wrapper.findComponent(EpicHeaderActions);
  const findIssuableBody = () => wrapper.findComponent(IssuableBody);

  const createComponent = () => {
    const store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    wrapper = shallowMount(EpicBody, { store });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders an issuable body component', () => {
    const { author } = mockEpicMeta;
    const { username } = author;

    expect(findIssuableBody().props()).toMatchObject({
      author: {
        ...author,
        username: username.startsWith('@') ? username.substring(1) : username,
        webUrl: author.url,
      },
      createdAt: '2015-07-03T10:00:00.000Z',
      endpoint: 'http://test.host',
      updateEndpoint: '/groups/frontend-fixtures-group/-/epics/1.json',
      canUpdate: true,
      enableAutocomplete: true,
      zoomMeetingUrl: '',
      publishedIncidentUrl: '',
      issuableRef: '',
      issuableStatus: 'opened',
      isConfidential: false,
      initialTitleHtml: 'This is a sample epic',
      initialTitleText: 'This is a sample epic',
    });
  });

  it('renders header', () => {
    expect(findEpicHeader().exists()).toBe(true);
  });

  it('renders actions dropdown', () => {
    expect(findEpicHeaderActions().exists()).toBe(true);
  });
});
