import { shallowMount } from '@vue/test-utils';
import EpicBody from 'ee/epic/components/epic_body.vue';
import createStore from 'ee/epic/store';
import IssuableBody from '~/issues/show/components/app.vue';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicBodyComponent', () => {
  let wrapper;

  const findIssuableBody = () => wrapper.findComponent(IssuableBody);

  const store = createStore();
  store.dispatch('setEpicMeta', mockEpicMeta);
  store.dispatch('setEpicData', mockEpicData);

  const createComponent = () => {
    wrapper = shallowMount(EpicBody, {
      store,
    });
  };

  it('renders an issuable body component', () => {
    createComponent();

    expect(findIssuableBody().exists()).toBe(true);
    expect(findIssuableBody().props()).toMatchObject({
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
});
