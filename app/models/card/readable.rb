module Card::Readable
  extend ActiveSupport::Concern

  def read_by(user)
    notifications_for(user).tap do |notifications|
      notifications.each(&:read)
    end
  end

  private
    def notifications_for(user)
      user.notifications.unread.where(source: notification_sources)
    end

    def notification_sources
      events + mentions + comment_mentions
    end

    def comment_mentions
      Mention.where(source: comments)
    end

    def comments
      Comment.where(id: messages.comments.pluck(:messageable_id))
    end
end
