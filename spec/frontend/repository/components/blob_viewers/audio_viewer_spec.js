import { shallowMount } from '@vue/test-utils';
import AudioViewer from '~/repository/components/blob_viewers/audio_viewer.vue';

describe('Audio Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/audio.mid',
  };

  const createComponent = () => {
    wrapper = shallowMount(AudioViewer, { propsData: { blob: DEFAULT_BLOB_DATA } });
  };

  const findImage = () => wrapper.find('[data-testid="audio"]');

  it('renders an audio source component', () => {
    createComponent();

    expect(findImage().exists()).toBe(true);
    expect(findImage().attributes('src')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
