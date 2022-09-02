import Cookies from '~/lib/utils/cookies';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import epicUtils from 'ee/epic/utils/epic_utils';

describe('epicUtils', () => {
  describe('toggleContainerClass', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="page-with-contextual-sidebar"></div>');
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('toggles provided class on containerEl', () => {
      const className = 'my-class';
      const containerEl = document.querySelector('.page-with-contextual-sidebar');

      containerEl.classList.add(className);
      epicUtils.toggleContainerClass(className);

      expect(containerEl.classList.contains(className)).toBe(false);
    });
  });

  describe('getCollapsedGutter', () => {
    let originalCollapsedGutter;

    beforeAll(() => {
      originalCollapsedGutter = Cookies.get('collapsed_gutter');
    });

    afterAll(() => {
      Cookies.set('collapsed_gutter', originalCollapsedGutter);
    });

    it('gets value of Cookie flag `collapsed_gutter` as boolean', () => {
      const collapsedGutterVal = true;
      Cookies.set('collapsed_gutter', collapsedGutterVal);

      expect(epicUtils.getCollapsedGutter()).toBe(collapsedGutterVal);
    });
  });

  describe('setCollapsedGutter', () => {
    let originalCollapsedGutter;

    beforeAll(() => {
      originalCollapsedGutter = Cookies.get('collapsed_gutter');
    });

    afterAll(() => {
      Cookies.set('collapsed_gutter', originalCollapsedGutter);
    });

    it('sets value of Cookie flag `collapsed_gutter` with provided `value` param', () => {
      const collapsedGutterVal = true;

      epicUtils.setCollapsedGutter(collapsedGutterVal);

      expect(Cookies.get('collapsed_gutter')).toBe(`${collapsedGutterVal}`); // Cookie value will always be string
    });
  });
});
