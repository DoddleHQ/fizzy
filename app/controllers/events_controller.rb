class EventsController < ApplicationController
  include BucketFilterable
  before_action :set_activity_day

  def index
    update_bucket_filter
    @buckets = Current.user.buckets.alphabetically
    @events = events_by_hour_and_column
    @next_day = latest_event_before_today&.created_at
  end

  private
    def events_by_hour_and_column
      user_events.where(created_at: @activity_day.all_day).
        group_by { |event| [ event.created_at.hour, helpers.event_column(event) ] }.
        map { |hour_col, events|
          [ hour_col,
            events.uniq { |e| e.action == "boosted" ? [ e.creator_id, e.bubble_id ] : e.id }
          ]
        }
    end

    def latest_event_before_today
      user_events.where(created_at: ...@activity_day.beginning_of_day).chronologically.last
    end

    def user_events
      Event.where(bubble: user_bubbles, creator: Current.account.users.without_system)
    end

    def user_bubbles
      Current.user.accessible_bubbles
            .published_or_drafted_by(Current.user)
            .where(bucket_id: bucket_filter)
    end

    def set_activity_day
      @activity_day = if params[:day].present?
        Time.zone.parse(params[:day])
      else
        Time.zone.now
      end
    rescue ArgumentError
      raise ActionController::RoutingError
    end
end
