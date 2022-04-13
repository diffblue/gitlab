# frozen_string_literal: true

class AddOtpSecretExpiresAt < Gitlab::Database::Migration[1.0]
  def change
    # rubocop: disable Migration/AddColumnsToWideTables
    add_column :users, :otp_secret_expires_at, :datetime_with_timezone
    # rubocop: enable Migration/AddColumnsToWideTables
  end
end
