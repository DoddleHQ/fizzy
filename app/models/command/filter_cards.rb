class Command::FilterCards < Command
  store_accessor :data, :card_ids, :params

  def title
    "Filter cards #{card_ids.join(", ")}"
  end

  def execute
    redirect_to cards_path(**params.without("card_ids").merge(card_ids: card_ids))
  end
end
