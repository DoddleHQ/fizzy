module Command::Cards
  extend ActiveSupport::Concern

  included do
    store_accessor :data, :card_ids

    validates_presence_of :card_ids, :cards
  end

  def undoable?
    true
  end

  def needs_confirmation?
    cards.many?
  end

  private
    def cards
      user.accessible_cards.where(id: card_ids)
    end

    def cards_description
      if cards.one?
        "card '#{cards.first.title}'"
      else
        "#{cards.count} cards"
      end
    end
end
