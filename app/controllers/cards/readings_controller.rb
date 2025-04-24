class Cards::ReadingsController < ApplicationController
  include CardScoped

  def create
    @notifications = @card.read_by(Current.user)
  end
end
