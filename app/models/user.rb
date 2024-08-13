class User < ApplicationRecord
  belongs_to :account
  has_many :sessions, dependent: :destroy
  has_many :splats, dependent: :destroy

  has_secure_password validations: false

  scope :active, -> { where(active: true) }

  def current?
    self == Current.user
  end

  def initials
    name.scan(/\b\w/).join
  end

  def deactivate
    transaction do
      sessions.delete_all
      update! active: false, email_address: deactived_email_address
    end
  end

  private
    def deactived_email_address
      email_address&.gsub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end
end
