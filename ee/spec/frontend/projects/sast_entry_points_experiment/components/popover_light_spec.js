import '~/commons';
import { GlPopover, GlButton, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import PopoverLight from 'ee/projects/sast_entry_points_experiment/components/popover_light.vue';
import { COOKIE_NAME } from 'ee/projects/sast_entry_points_experiment/constants';
import ExperimentTracking from '~/experimentation/experiment_tracking';

jest.mock('~/experimentation/experiment_tracking');

let wrapper;

const sastDocumentationPath = 'sast_documentation_path';
const findPopover = () => wrapper.findComponent(GlPopover);
const findCtaLink = () => findPopover().findComponent(GlLink);
const findCloseButton = () => findPopover().findComponent(GlButton);

function createComponent() {
  wrapper = mount(PopoverLight, {
    propsData: { sastDocumentationPath },
  });
}

afterEach(() => {
  wrapper.destroy();
  Cookies.remove(COOKIE_NAME);
});

describe('When the cookie is set', () => {
  beforeEach(() => {
    Cookies.set(COOKIE_NAME, 'true', { expires: 365 });
    createComponent();
  });

  it('does not render the component', () => {
    expect(findPopover().exists()).toBe(false);
  });
});

describe('When the cookie is not set', () => {
  beforeEach(() => {
    createComponent();
  });

  it('renders the component', () => {
    expect(findPopover().exists()).toBe(true);
  });

  it('tracks the show event', () => {
    expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith('show');
  });

  it('uses the sastDocumentationPath from the props for the button link', () => {
    expect(findCtaLink().attributes('href')).toBe(sastDocumentationPath);
  });

  it('matches the snapshot', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('When clicking the CTA button', () => {
    beforeEach(() => {
      findCtaLink().vm.$emit('click');
    });

    it('tracks the cta_clicked event', () => {
      expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith('cta_clicked');
    });

    it('sets a cookie', () => {
      expect(Cookies.get(COOKIE_NAME)).toBe('true');
    });
  });

  describe('When dismissing the component', () => {
    beforeEach(() => {
      findCloseButton().vm.$emit('click');
    });

    it('tracks the dismissed event', () => {
      expect(ExperimentTracking.prototype.event).toHaveBeenCalledWith('dismissed');
    });

    it('sets a cookie', () => {
      expect(Cookies.get(COOKIE_NAME)).toBe('true');
    });

    it('hides the component', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });
});
