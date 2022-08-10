import Cookies from '~/lib/utils/cookies';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initEETrialBanner from 'ee/ee_trial_banner';

describe('EE gitlab license banner dismiss', () => {
  const dismiss = () => {
    const button = document.querySelector('.js-close');
    button.click();
  };

  const dismissOnChildElement = () => {
    const childElement = document.querySelector('.child-element');
    childElement.click();
  };

  const renew = () => {
    const button = document.querySelector('.gl-button');
    button.click();
  };

  const isHidden = () =>
    document.querySelector('.js-gitlab-ee-license-banner').classList.contains('hidden');

  beforeEach(() => {
    setHTMLFixture(`
    <div class="js-gitlab-ee-license-banner">
      <button class="js-close"><span class="child-element">X</span></button>
      <a href="#" class="btn gl-button btn-confirm"></a>
    </div>
    `);

    initEETrialBanner();
  });

  afterEach(() => {
    Cookies.remove('show_ee_trial_banner');

    resetHTMLFixture();
  });

  it('should remove the license banner when a close button is clicked', () => {
    expect(isHidden()).toBe(false);

    dismiss();

    expect(isHidden()).toBe(true);
  });

  it('should remove the license banner when an element inside close button is clicked', () => {
    expect(isHidden()).toBe(false);

    dismissOnChildElement();

    expect(isHidden()).toBe(true);
  });

  it('calls Cookies.set for `show_ee_trial_banner` when a close button is clicked', () => {
    jest.spyOn(Cookies, 'set');
    dismiss();

    expect(Cookies.set).toHaveBeenCalledWith('show_ee_trial_banner', 'false', {
      expires: 365,
      secure: false,
    });
  });

  it('should not call Cookies.set for `show_ee_trial_banner` when a non close button is clicked', () => {
    jest.spyOn(Cookies, 'set');
    renew();

    expect(Cookies.set).not.toHaveBeenCalled();
  });
});
