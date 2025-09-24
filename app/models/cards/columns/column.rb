class Cards::OldColumns::Column
  attr_reader :page, :filter, :user_filtering

  def initialize(page:, filter:, user_filtering:)
    @page = page
    @filter = filter
    @user_filtering = user_filtering
  end

  def cards
    page.records
  end

  def cache_key
    ActiveSupport::Cache.expand_cache_key([ cards ])
  end
end
