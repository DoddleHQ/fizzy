class Command::Close < Command
  include Command::Cards

  store_accessor :data, :reason, :closed_card_ids

  def title
    "Close #{cards_description}"
  end

  def execute
    closed_card_ids = []

    transaction do
      cards.find_each do |card|
        closed_card_ids << card.id
        card.close(user: user, reason: reason.presence || Closure::Reason.default)
      end

      update! closed_card_ids: closed_card_ids
    end
  end

  def undo
    transaction do
      closed_cards.find_each do |card|
        card.reopen
      end
    end
  end

  private
    def closed_cards
      user.accessible_cards.where(id: closed_card_ids)
    end
end
