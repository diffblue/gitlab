# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ssh::Signature do
  # ssh-keygen -t ed25519
  let_it_be(:committer_email) { 'ssh-commit-test@example.com' }
  let_it_be(:public_key_text) { 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIELaINtPpdqTHD57qGll7jacPbuzsz5yc3S1KJ9PhCzU' }
  let_it_be_with_reload(:user) { create(:user, email: committer_email) }
  let_it_be_with_reload(:key) { create(:key, key: public_key_text, user: user) }

  let(:signed_text) do
    <<~MSG
      This message was signed by an ssh key
      The pubkey fingerprint is SHA256:Ruhtd6QtIH0Kxx+/x4tCDtJOTsccvAokHfQDDoSc0ww
    MSG
  end

  let(:signature_text) do
    # ssh-keygen -Y sign -n file -f id_test message.txt
    <<~SIG
      -----BEGIN SSH SIGNATURE-----
      U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgQtog20+l2pMcPnuoaWXuNpw9u7
      OzPnJzdLUon0+ELNQAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
      OQAAAEBwmvXtKb65HbQTJAo2dOL/MQOaWUzS9LNlIM6QUeXjwxljPoNACuZ87108yABIIB
      hvIGuYkoHlRk0CbSJv5gAK
      -----END SSH SIGNATURE-----
    SIG
  end

  subject(:signature) do
    described_class.new(
      signature_text,
      signed_text,
      committer_email
    )
  end

  RSpec.shared_examples 'verified signature' do
    it 'reports verified status' do
      expect(signature.verification_status).to eq(:verified)
      expect(signature.valid?).to eq(true)
      expect(signature.verified_key).to eq(key)
    end
  end

  RSpec.shared_examples 'unverified signature' do
    it 'reports unverified status' do
      expect(signature.verification_status).to eq(:unverified)
      expect(signature.valid?).to eq(false)
      expect(signature.verified_key).to be_nil
    end
  end

  describe 'signature verification' do
    context 'when signature is valid and user email is verified' do
      it_behaves_like 'verified signature'
    end

    context 'when using an RSA key' do
      let(:public_key_text) do
        <<~KEY.delete("\n")
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDjTNX4pLpKHyrqs6Cll+nB1HAQnGGj+b5x
        wCCpmF4bfWtB7Ei7uSOJBF0twnUiDp1diyuOwQqOBcze4slv2dr8PlssnUE5uq6DMkoYKoau
        IhKXsrW2jclPY8DEhp2JchSxluFwSa6rxI+5ijMUeb6qrVaZ7rtBNYjokR6qv9fwwK8wOgDL
        /KldKR45fKCWV6s+3yXZkl9OxlPSbZmv9WaJck9JxOqu/6obwGDfG/VLwed0DaOkW/ciAvmf
        Eso9PNBj+IzWgn928BgtNGeo5nWmvWbZEwQovRoj7XwPlD7utxT/dInMsiP7VUDW7ElpGgao
        LxBfKcLxG/couhaxx2H9//d2pYsazZw0Suvv7viODKiMftAF7oH784ulqBbJAAW3iH+wmh6o
        AGAC57QdVjbOV3lHAujVk7bGzcjgEmmfTP3JO0qRRw/rhXH0IA8IC8o4fT7m37qUEdz6GQhZ
        G5Q8OifgTkwAA1MJh9DK0vXQRarJT7W/6x4gqjiEh9dy538=
        KEY
      end

      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAAZcAAAAHc3NoLXJzYQAAAAMBAAEAAAGBAONM1fikukofKuqzoKWX6c
          HUcBCcYaP5vnHAIKmYXht9a0HsSLu5I4kEXS3CdSIOnV2LK47BCo4FzN7iyW/Z2vw+Wyyd
          QTm6roMyShgqhq4iEpeytbaNyU9jwMSGnYlyFLGW4XBJrqvEj7mKMxR5vqqtVpnuu0E1iO
          iRHqq/1/DArzA6AMv8qV0pHjl8oJZXqz7fJdmSX07GU9Jtma/1ZolyT0nE6q7/qhvAYN8b
          9UvB53QNo6Rb9yIC+Z8Syj080GP4jNaCf3bwGC00Z6jmdaa9ZtkTBCi9GiPtfA+UPu63FP
          90icyyI/tVQNbsSWkaBqgvEF8pwvEb9yi6FrHHYf3/93alixrNnDRK6+/u+I4MqIx+0AXu
          gfvzi6WoFskABbeIf7CaHqgAYALntB1WNs5XeUcC6NWTtsbNyOASaZ9M/ck7SpFHD+uFcf
          QgDwgLyjh9PubfupQR3PoZCFkblDw6J+BOTAADUwmH0MrS9dBFqslPtb/rHiCqOISH13Ln
          fwAAAARmaWxlAAAAAAAAAAZzaGE1MTIAAAGUAAAADHJzYS1zaGEyLTUxMgAAAYBtEPh9YE
          K6DvY9hVWwiry5bJQcoZ8B/jneGcCq4SK4lbqZf+Es2t6VYgXdSn/Yb/M8Ka6zOmHxaqED
          AL0A8ZGMNGcklM4fNdYqy6SlivZKTTdppT+KyBQeoYOAmNWkvds4QhI3fWIrKWFNSgIAt5
          bgAfwCdRMpSmvRT0AmNxpPxTCwKFzpbHJis2g6cFBVkq5Uglyxc2Td9IhzAL3ByILrxFZk
          5EhrYOkRQ0osrOyaJQvST3KIbHZRfmWl9mgw0vCqJOm14xqftYVbwBkYqPuwqkke5/Cd4E
          90oFCHRi1nFmJeO/nqk09Mmu2jHvx+u8S6Kb557i4ELaqETK0ytkLfoXcnMSyUXx+kbnQd
          ERikCESJvfPPqEJbf45hSurBVNJMlSza0xIkuQpyCUFJ4QeqTO2uz4GfM+itU4tLugcYSI
          U2rN+mPCr4xJv9tAgPp93Tx/TVa12bpaZIhoOHCIt34V7pLL0cozVJ+fVtUiQtPcqmDjko
          t1U0t1Nt6DGtfIg=
          -----END SSH SIGNATURE-----
        SIG
      end

      before do
        key.update!(key: public_key_text)
      end

      it_behaves_like 'verified signature'
    end

    context 'when user email is not verified' do
      before do
        user.update!(confirmed_at: nil)
      end

      it_behaves_like 'unverified signature'
    end

    context 'when no user exists with the committer email' do
      let(:committer_email) { 'different-email+ssh-commit-test@example.com' }

      it_behaves_like 'unverified signature'
    end

    context 'when signature is invalid' do
      let(:signature_text) do
        # truncated base64
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgQtog20+l2pMcPnuoaWXuNpw9u7
          OzPnJzdLUon0+ELNQAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAEBwmvXtKb65HbQTJAo2dOL/MQOaWUzS9LNlIM6QUeXjwxljPoNACuZ87108yABIIB
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when signature is for a different message' do
      let(:signature_text) do
        <<~SIG
          -----BEGIN SSH SIGNATURE-----
          U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgQtog20+l2pMcPnuoaWXuNpw9u7
          OzPnJzdLUon0+ELNQAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
          OQAAAEB3/B+6c3+XqEuqjiqlVQwQmUdj8WquROtkhdtScEOP8GXcGQx+aaQs5nq4ZJCuu5
          ywcU+4xQaLVpCf7tfGWa4K
          -----END SSH SIGNATURE-----
        SIG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when message has been tampered' do
      let(:signed_text) do
        <<~MSG
          This message was signed by an ssh key
          The pubkey fingerprint is SHA256:RjzeOilYHkiHqz5fefdnrWr8qn5nbroAisuuTMoH9PU
        MSG
      end

      it_behaves_like 'unverified signature'
    end

    context 'when key does not exist in GitLab' do
      before do
        key.delete
      end

      it 'reports unknown_key status' do
        expect(signature.verification_status).to eq(:unknown_key)
        expect(signature.valid?).to eq(false)
        expect(signature.verified_key).to be_nil
      end
    end

    context 'when key belongs to someone other than the committer' do
      let_it_be(:other_user) { create(:user, email: 'other-user@example.com') }

      let(:committer_email) { other_user.email }

      it 'reports other_user status' do
        expect(signature.verification_status).to eq(:other_user)
        expect(signature.valid?).to eq(false)
        expect(signature.verified_key).to be_nil
      end
    end
  end
end
