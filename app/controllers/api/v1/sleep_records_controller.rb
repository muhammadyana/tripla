module Api
  module V1
    class SleepRecordsController < ApplicationController
      def index
        sleep_records = Rails.cache.fetch("user_sleep_records_#{current_user.id}", expires_in: 1.hour) do
          current_user.sleep_records.desc
        end

        pagy, sleep_records = pagy(sleep_records, limit: per_page)

        responder(:ok, SleepRecordSerializer.new(sleep_records).to_hash.merge(pagination: pagy))
      end

      def clock_in
        sleep_record = current_user.sleep_records.create!(clock_in_time: Time.current)

        responder(:created, SleepRecordSerializer.new(sleep_record))
      end

      def clock_out
        current_user.sleep_records.clock_out_all
        pagy, sleep_records = pagy(sleep_records = current_user.sleep_records.desc, limit: per_page)
        responder(:ok, SleepRecordSerializer.new(sleep_records).to_hash.merge(pagination: pagy))
      end

      def following_sleep_records
        sleep_records = Rails.cache.fetch("following_sleep_records_#{current_user.id}", expires_in: 1.hour) do
          SleepRecord
            .joins(:user)
            .merge(User.joins(:followers).where(followers: { id: current_user.id }))
            .for_week
            .completed
            .order(duration_seconds: :desc)
        end

        @pagy, @paginated_sleep_records = pagy(sleep_records, limit: per_page)
        responder(:ok, SleepRecordSerializer.new(@paginated_sleep_records).to_hash.merge(pagination: @pagy))
      end
    end
  end
end
