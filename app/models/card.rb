class Card < ApplicationRecord
  include Assignable, Colored, Engageable, Eventable, Golden, Mentions,
    Messages, Pinnable, Closeable, Readable, Searchable, Staged,
    Statuses, Taggable, Watchable

  belongs_to :collection, touch: true
  belongs_to :creator, class_name: "User", default: -> { Current.user }

  has_one_attached :image, dependent: :purge_later

  has_markdown :description

  scope :reverse_chronologically, -> { order created_at: :desc, id: :desc }
  scope :chronologically, -> { order created_at: :asc, id: :asc }
  scope :latest, -> { order updated_at: :desc, id: :desc }

  scope :indexed_by, ->(index) do
    case index
    when "newest"  then reverse_chronologically
    when "oldest"  then chronologically
    when "latest"  then latest
    when "stalled" then chronologically
    when "closed"  then closed
    end
  end

  def title=(new_title)
    self[:title] = new_title.presence || "Untitled"
  end

  def cache_key
    [ super, collection.name ].compact.join("/")
  end

  def was_mentioned(mention)
    watch_by(mention.mentionee)
  end
end
