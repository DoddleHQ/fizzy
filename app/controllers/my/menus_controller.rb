class My::MenusController < ApplicationController
  include FilterScoped

  before_action :enable_referral_collection_filtering, if: :collection_filtering_enabled?

  def show
    fresh_when @user_filtering
  end

  private
    def collection_filtering_enabled?
      params[:enable_collection_filtering].present?
    end
end
