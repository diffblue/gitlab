# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::BannerComponent, type: :component do
  subject do
    described_class.new(**options)
  end

  let(:title) { "Banner title" }
  let(:content) { "Banner content"}
  let(:options) { {} }

  describe 'basic usage' do
    before do
      render_inline(subject) do |c|
        c.title { title }
        content
      end
    end

    it 'renders its content' do
      expect(rendered_component).to have_text content
    end

    it 'renders its title' do
      expect(rendered_component).to have_css "h1[class='gl-banner-title']", text: title
    end

    it 'renders a close button' do
      expect(rendered_component).to have_css "button.gl-banner-close"
    end

    describe 'banner_options' do
      let(:options) { { banner_options: { class: "baz", data: { foo: "bar" } } } }

      it 'are on the banner' do
        expect(rendered_component).to have_css ".gl-banner.baz[data-foo='bar']"
      end

      context 'with custom classes' do
        let(:options) { { variant: :introduction, banner_options: { class: 'extra special' } } }

        it 'don\'t conflict with internal banner_classes' do
          expect(rendered_component).to have_css '.extra.special.gl-banner-introduction.gl-banner'
        end
      end
    end

    describe 'close_options' do
      let(:options) { { close_options: { class: "js-foo", data: { uid: "123" } } } }

      it 'are on the close button' do
        expect(rendered_component).to have_css "button.gl-banner-close.js-foo[data-uid='123']"
      end
    end

    describe 'embedded' do
      context 'by default (false)' do
        it 'keeps the banner\'s borders' do
          expect(rendered_component).not_to have_css ".gl-banner.gl-border-none"
        end
      end

      context 'when set to true' do
        let(:options) { { embedded: true } }

        it 'removes the banner\'s borders' do
          expect(rendered_component).to have_css ".gl-banner.gl-border-none"
        end
      end
    end

    describe 'variant' do
      context 'by default (promotion)' do
        it 'applies no variant class' do
          expect(rendered_component).to have_css "[class='gl-banner']"
        end
      end

      context 'when set to introduction' do
        let(:options) { { variant: :introduction } }

        it "applies the introduction class to the banner" do
          expect(rendered_component).to have_css ".gl-banner.gl-banner-introduction"
        end

        it "applies the confirm class to the close button" do
          expect(rendered_component).to have_css ".gl-banner-close.btn-confirm.btn-confirm-tertiary"
        end
      end

      context 'when set to unknown variant' do
        let(:options) { { variant: :foobar } }

        it 'ignores the unknown variant' do
          expect(rendered_component).to have_css "[class='gl-banner']"
        end
      end
    end

    describe 'illustration' do
      it 'has none by default' do
        expect(rendered_component).not_to have_css ".gl-banner-illustration"
      end
    end
  end

  context 'with illustration' do
    before do
      render_inline(subject) do |c|
        c.title { title }
        c.illustration { "<svg></svg>".html_safe }
        content
      end
    end

    it 'renders an illustration image' do
      expect(rendered_component).to have_css ".gl-banner-illustration svg"
    end
  end
end
