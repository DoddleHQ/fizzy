class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def account
    user.account
  end
end
