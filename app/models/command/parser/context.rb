class Command::Parser::Context
  attr_reader :user

  def initialize(user, url:)
    @user = user
    extract_url_components(url)
  end

  def cards
    if controller == "cards" && action == "show"
      user.accessible_cards.where id: params[:id]
    elsif controller == "cards" && action == "index"
      filter.cards
    else
      Card.none
    end
  end

  def filter
    user.filters.from_params(params.permit(*Filter::Params::PERMITTED_PARAMS).reverse_merge(**FilterScoped::DEFAULT_PARAMS))
  end

  private
    attr_reader :controller, :action, :params

    def extract_url_components(url)
      uri = URI.parse(url || "")
      route = Rails.application.routes.recognize_path(uri.path)
      @controller = route[:controller]
      @action = route[:action]
      @params =  ActionController::Parameters.new(Rack::Utils.parse_nested_query(uri.query).merge(route.except(:controller, :action)))
    end
end
